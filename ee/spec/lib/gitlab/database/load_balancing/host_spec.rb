require 'spec_helper'

describe Gitlab::Database::LoadBalancing::Host, :postgresql do
  let(:load_balancer) do
    Gitlab::Database::LoadBalancing::LoadBalancer.new(%w[localhost])
  end

  let(:host) { load_balancer.host_list.hosts.first }

  before do
    allow(Gitlab::Database).to receive(:create_connection_pool)
      .and_return(ActiveRecord::Base.connection_pool)
  end

  describe '#connection' do
    it 'returns a connection from the pool' do
      expect(host.pool).to receive(:connection)

      host.connection
    end
  end

  describe '#release_connection' do
    it 'releases the current connection from the pool' do
      expect(host.pool).to receive(:release_connection)

      host.release_connection
    end
  end

  describe '#offline!' do
    it 'marks the host as offline' do
      expect(host.pool).to receive(:disconnect!)

      host.offline!
    end
  end

  describe '#online?' do
    context 'when the replica status is recent enough' do
      it 'returns the latest status' do
        Timecop.freeze do
          host = described_class.new('localhost', load_balancer)

          expect(host).not_to receive(:refresh_status)
          expect(host).to be_online
        end
      end
    end

    context 'when the replica status is outdated' do
      it 'refreshes the status' do
        host.offline!

        expect(host)
          .to receive(:check_replica_status?)
          .and_return(true)

        expect(host).to be_online
      end
    end

    context 'when the replica is not online' do
      it 'returns false when ActionView::Template::Error is raised' do
        error = StandardError.new

        allow(host)
          .to receive(:check_replica_status?)
          .and_raise(ActionView::Template::Error.new('boom', error))

        expect(host).not_to be_online
      end

      it 'returns false when ActiveRecord::StatementInvalid is raised' do
        allow(host)
          .to receive(:check_replica_status?)
          .and_raise(ActiveRecord::StatementInvalid.new('foo'))

        expect(host).not_to be_online
      end

      if Gitlab::Database.postgresql?
        it 'returns false when PG::Error is raised' do
          allow(host)
            .to receive(:check_replica_status?)
            .and_raise(PG::Error)

          expect(host).not_to be_online
        end
      end
    end
  end

  describe '#refresh_status' do
    it 'refreshes the status' do
      host.offline!

      expect(host)
        .to receive(:replica_is_up_to_date?)
        .and_call_original

      host.refresh_status

      expect(host).to be_online
    end
  end

  describe '#check_replica_status?' do
    it 'returns true when we need to check the replica status' do
      allow(host)
        .to receive(:last_checked_at)
        .and_return(1.year.ago)

      expect(host.check_replica_status?).to eq(true)
    end

    it 'returns false when we do not need to check the replica status' do
      Timecop.freeze do
        allow(host)
          .to receive(:last_checked_at)
          .and_return(Time.zone.now)

        expect(host.check_replica_status?).to eq(false)
      end
    end
  end

  describe '#replica_is_up_to_date?' do
    context 'when the lag time is below the threshold' do
      it 'returns true' do
        expect(host)
          .to receive(:replication_lag_below_threshold?)
          .and_return(true)

        expect(host.replica_is_up_to_date?).to eq(true)
      end
    end

    context 'when the lag time exceeds the threshold' do
      before do
        allow(host)
          .to receive(:replication_lag_below_threshold?)
          .and_return(false)
      end

      it 'returns true if the data is recent enough' do
        expect(host)
          .to receive(:data_is_recent_enough?)
          .and_return(true)

        expect(host.replica_is_up_to_date?).to eq(true)
      end

      it 'returns false when the data is not recent enough' do
        expect(host)
          .to receive(:data_is_recent_enough?)
          .and_return(false)

        expect(host.replica_is_up_to_date?).to eq(false)
      end
    end
  end

  describe '#replication_lag_below_threshold' do
    it 'returns true when the lag time is below the threshold' do
      expect(host)
        .to receive(:replication_lag_time)
        .and_return(1)

      expect(host.replication_lag_below_threshold?).to eq(true)
    end

    it 'returns false when the lag time exceeds the threshold' do
      expect(host)
        .to receive(:replication_lag_time)
        .and_return(9000)

      expect(host.replication_lag_below_threshold?).to eq(false)
    end

    it 'returns false when no lag time could be calculated' do
      expect(host)
        .to receive(:replication_lag_time)
        .and_return(nil)

      expect(host.replication_lag_below_threshold?).to eq(false)
    end
  end

  describe '#data_is_recent_enough?' do
    it 'returns true when the data is recent enough' do
      expect(host.data_is_recent_enough?).to eq(true)
    end

    it 'returns false when the data is not recent enough' do
      diff = Gitlab::Database::LoadBalancing.max_replication_difference * 2

      expect(host)
        .to receive(:query_and_release)
        .and_return({ 'diff' => diff })

      expect(host.data_is_recent_enough?).to eq(false)
    end

    it 'returns false when no lag size could be calculated' do
      expect(host)
        .to receive(:replication_lag_size)
        .and_return(nil)

      expect(host.data_is_recent_enough?).to eq(false)
    end
  end

  describe '#replication_lag_time' do
    it 'returns the lag time as a Float' do
      expect(host.replication_lag_time).to be_an_instance_of(Float)
    end

    it 'returns nil when the database query returned no rows' do
      expect(host)
        .to receive(:query_and_release)
        .and_return({})

      expect(host.replication_lag_time).to be_nil
    end
  end

  describe '#replication_lag_size' do
    it 'returns the lag size as an Integer' do
      # On newer versions of Ruby the class is Integer, but on CI we run a
      # version that still uses Fixnum.
      expect([Fixnum, Integer]).to include(host.replication_lag_size.class) # rubocop: disable Lint/UnifiedInteger
    end

    it 'returns nil when the database query returned no rows' do
      expect(host)
        .to receive(:query_and_release)
        .and_return({})

      expect(host.replication_lag_size).to be_nil
    end

    it 'returns nil when the database connection fails' do
      allow(host)
        .to receive(:connection)
        .and_raise(ActionView::Template::Error.new('boom', StandardError.new))

      expect(host.replication_lag_size).to be_nil
    end
  end

  describe '#primary_write_location' do
    it 'returns the write location of the primary' do
      expect(host.primary_write_location).to be_an_instance_of(String)
      expect(host.primary_write_location).not_to be_empty
    end
  end

  describe '#caught_up?' do
    let(:connection) { double(:connection) }

    before do
      allow(connection).to receive(:quote).and_return('foo')
    end

    it 'returns true when a host has caught up' do
      allow(host).to receive(:connection).and_return(connection)
      expect(connection).to receive(:select_all).and_return([{ 'result' => 't' }])

      expect(host.caught_up?('foo')).to eq(true)
    end

    it 'returns false when a host has not caught up' do
      allow(host).to receive(:connection).and_return(connection)
      expect(connection).to receive(:select_all).and_return([{ 'result' => 'f' }])

      expect(host.caught_up?('foo')).to eq(false)
    end

    it 'returns false when the connection fails' do
      allow(host)
        .to receive(:connection)
        .and_raise(ActionView::Template::Error.new('boom', StandardError.new))

      expect(host.caught_up?('foo')).to eq(false)
    end
  end

  describe '#query_and_release' do
    it 'executes a SQL query' do
      results = host.query_and_release('SELECT 10 AS number')

      expect(results).to be_an_instance_of(Hash)
      expect(results['number'].to_i).to eq(10)
    end

    it 'releases the connection after running the query' do
      expect(host)
        .to receive(:release_connection)
        .once

      host.query_and_release('SELECT 10 AS number')
    end

    it 'returns an empty Hash in the event of an error' do
      expect(host.connection)
        .to receive(:select_all)
        .and_raise(RuntimeError, 'kittens')

      expect(host.query_and_release('SELECT 10 AS number')).to eq({})
    end
  end
end
