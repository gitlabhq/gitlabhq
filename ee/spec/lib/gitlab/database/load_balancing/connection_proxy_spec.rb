require 'spec_helper'

describe Gitlab::Database::LoadBalancing::ConnectionProxy do
  let(:proxy) { described_class.new }

  describe '#select' do
    it 'performs a read' do
      expect(proxy).to receive(:read_using_load_balancer).with(:select, ['foo'])

      proxy.select('foo')
    end
  end

  describe '#select_all' do
    describe 'using a SELECT query' do
      it 'runs the query on a secondary' do
        arel = double(:arel)

        expect(proxy).to receive(:read_using_load_balancer)
          .with(:select_all, [arel, 'foo', []])

        proxy.select_all(arel, 'foo')
      end
    end

    describe 'using a SELECT FOR UPDATE query' do
      it 'runs the query on the primary and sticks to it' do
        arel = double(:arel, locked: true)

        expect(proxy).to receive(:write_using_load_balancer)
          .with(:select_all, [arel, 'foo', []], sticky: true)

        proxy.select_all(arel, 'foo')
      end
    end
  end

  Gitlab::Database::LoadBalancing::ConnectionProxy::STICKY_WRITES.each do |name|
    describe "#{name}" do
      it 'runs the query on the primary and sticks to it' do
        expect(proxy).to receive(:write_using_load_balancer)
          .with(name, ['foo'], sticky: true)

        proxy.send(name, 'foo')
      end
    end
  end

  # We have an extra test for #transaction here to make sure that nested queries
  # are also sent to a primary.
  describe '#transaction' do
    let(:session) { Gitlab::Database::LoadBalancing::Session.new }

    before do
      allow(Gitlab::Database::LoadBalancing::Session)
        .to receive(:current)
        .and_return(session)

      allow(proxy.load_balancer)
        .to receive(:primary_write_location)
        .and_return('123/ABC')
    end

    it 'runs the transaction and any nested queries on the primary' do
      primary = double(:connection)

      allow(primary).to receive(:transaction).and_yield
      allow(primary).to receive(:select)

      expect(proxy.load_balancer).to receive(:read_write)
        .twice
        .and_yield(primary)

      # This expectation is put in place to ensure no read is performed.
      expect(proxy.load_balancer).not_to receive(:read)

      proxy.transaction { proxy.select('true') }

      expect(session.use_primary?).to eq(true)
    end

    it 'tracks the state of the transaction in the session' do
      expect(proxy)
        .to receive(:write_using_load_balancer)
        .with(:transaction, [10], { sticky: true })

      expect(session).to receive(:enter_transaction)
      expect(session).to receive(:leave_transaction)

      proxy.transaction(10)
    end

    it 'records the last write location' do
      allow(proxy)
        .to receive(:write_using_load_balancer)
        .with(:transaction, [10], { sticky: true })

      proxy.transaction(10)

      expect(session.last_write_location).to eq('123/ABC')
    end
  end

  describe '#method_missing' do
    it 'runs the query on the primary without sticking to it' do
      expect(proxy).to receive(:write_using_load_balancer)
        .with(:foo, ['foo'])

      proxy.foo('foo')
    end

    it 'properly forwards trailing hash arguments' do
      allow(proxy.load_balancer).to receive(:read_write)

      expect(proxy).to receive(:write_using_load_balancer).and_call_original

      expect { proxy.case_sensitive_comparison(:table, :attribute, :column, { value: :value, format: :format }) }
        .not_to raise_error
    end
  end

  describe '#read_using_load_balancer' do
    let(:session) { Gitlab::Database::LoadBalancing::Session.new }
    let(:connection) { double(:connection) }

    before do
      allow(Gitlab::Database::LoadBalancing::Session)
        .to receive(:current)
        .and_return(session)
    end

    it 'performs a read-only query' do
      allow(proxy.load_balancer)
        .to receive(:load_balancer_method_for_read)
        .and_return(:read)

      allow(proxy.load_balancer)
        .to receive(:read)
        .and_yield(connection)

      expect(connection)
        .to receive(:foo)
        .with('foo')

      proxy.read_using_load_balancer(:foo, ['foo'])
    end
  end

  describe '#write_using_load_balancer' do
    let(:session) { Gitlab::Database::LoadBalancing::Session.new }
    let(:connection) { double(:connection) }

    before do
      allow(Gitlab::Database::LoadBalancing::Session)
        .to receive(:current)
        .and_return(session)

      allow(proxy.load_balancer)
        .to receive(:primary_write_location)
        .and_return('123/ABC')

      allow(proxy.load_balancer)
        .to receive(:read_write)
        .and_yield(connection)

      allow(connection)
        .to receive(:foo)
        .with('foo')
    end

    it 'it uses but does not stick to the primary when sticking is disabled' do
      expect(session).not_to receive(:write!)

      proxy.write_using_load_balancer(:foo, ['foo'])
    end

    it 'sticks to the primary when sticking is enabled' do
      expect(session).to receive(:write!)

      proxy.write_using_load_balancer(:foo, ['foo'], sticky: true)
    end

    it 'tracks the last write location' do
      proxy.write_using_load_balancer(:foo, ['foo'], sticky: true)

      expect(session.last_write_location).to be_instance_of(String)
    end

    it 'does not track the last write location inside a transaction' do
      session.enter_transaction

      proxy.write_using_load_balancer(:foo, ['foo'], sticky: true)

      expect(session.last_write_location).to be_nil
    end

    it 'does not track the last write location if sticking is not needed' do
      proxy.write_using_load_balancer(:foo, ['foo'], sticky: false)

      expect(session.last_write_location).to be_nil
    end
  end

  describe '#load_balancer_method_for_read' do
    let(:session) { Gitlab::Database::LoadBalancing::Session.new }

    before do
      allow(Gitlab::Database::LoadBalancing::Session)
        .to receive(:current)
        .and_return(session)
    end

    context 'when using the primary' do
      before do
        session.use_primary!
      end

      it 'returns :read_write when in a transaction' do
        session.enter_transaction

        expect(proxy.load_balancer_method_for_read).to eq(:read_write)
      end

      it 'returns :read_write if the secondaries are not in sync' do
        session.last_write_location = '123/ABC'

        allow(proxy.load_balancer)
          .to receive(:all_caught_up?)
          .with('123/ABC')
          .and_return(false)

        expect(proxy.load_balancer_method_for_read).to eq(:read_write)
      end

      it 'returns :read if all secondaries are in sync' do
        session.last_write_location = '123/ABC'

        allow(proxy.load_balancer)
          .to receive(:all_caught_up?)
          .with('123/ABC')
          .and_return(true)

        expect(proxy.load_balancer_method_for_read).to eq(:read)

        expect(session.use_primary?).to eq(false)
      end
    end

    context 'when using a secondary' do
      it 'returns :read' do
        expect(proxy.load_balancer_method_for_read).to eq(:read)
      end
    end
  end
end
