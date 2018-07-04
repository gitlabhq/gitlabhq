require 'spec_helper'

describe Gitlab::Database::LoadBalancing::HostList do
  before do
    allow(Gitlab::Database)
      .to receive(:create_connection_pool)
      .and_return(ActiveRecord::Base.connection_pool)
  end

  let(:load_balancer) { double(:load_balancer) }

  let(:host_list) do
    hosts = Array.new(2) do
      Gitlab::Database::LoadBalancing::Host.new('localhost', load_balancer)
    end

    described_class.new(hosts)
  end

  describe '#length' do
    it 'returns the number of hosts in the list' do
      expect(host_list.length).to eq(2)
    end
  end

  describe '#host_names' do
    it 'returns the host names of all hosts' do
      expect(host_list.host_names).to eq(%w[localhost localhost])
    end
  end

  describe '#hosts=' do
    it 'updates the list of hosts to use' do
      host_list.hosts = [
        Gitlab::Database::LoadBalancing::Host.new('foo', load_balancer)
      ]

      expect(host_list.length).to eq(1)
      expect(host_list.hosts[0].host).to eq('foo')
    end
  end

  describe '#next' do
    it 'returns a host' do
      expect(host_list.next)
        .to be_an_instance_of(Gitlab::Database::LoadBalancing::Host)
    end

    it 'cycles through all available hosts' do
      expect(host_list.next).to eq(host_list.hosts[0])
      expect(host_list.next).to eq(host_list.hosts[1])
      expect(host_list.next).to eq(host_list.hosts[0])
    end

    it 'skips hosts that are offline' do
      allow(host_list.hosts[0]).to receive(:online?).and_return(false)

      expect(host_list.next).to eq(host_list.hosts[1])
    end

    it 'returns nil if no hosts are online' do
      host_list.hosts.each do |host|
        allow(host).to receive(:online?).and_return(false)
      end

      expect(host_list.next).to be_nil
    end

    it 'returns nil if no hosts are available' do
      expect(described_class.new.next).to be_nil
    end
  end
end
