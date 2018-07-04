# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Database::LoadBalancing::ServiceDiscovery do
  let(:service) do
    described_class.new(nameserver: 'localhost', port: 8600, record: 'foo')
  end

  describe '#start' do
    before do
      allow(service)
        .to receive(:loop)
        .and_yield
    end

    it 'starts service discovery in a new thread' do
      expect(service)
        .to receive(:refresh_if_necessary)
        .and_return(5)

      expect(service)
        .to receive(:rand)
        .and_return(2)

      expect(service)
        .to receive(:sleep)
        .with(7)

      service.start.join
    end

    it 'reports exceptions to Sentry' do
      error = StandardError.new

      expect(service)
        .to receive(:refresh_if_necessary)
        .and_raise(error)

      expect(Raven)
        .to receive(:capture_exception)
        .with(error)

      expect(service)
        .to receive(:rand)
        .and_return(2)

      expect(service)
        .to receive(:sleep)
        .with(62)

      service.start.join
    end
  end

  describe '#refresh_if_necessary' do
    context 'when a refresh is necessary' do
      before do
        allow(service)
          .to receive(:addresses_from_load_balancer)
          .and_return(%w[localhost])

        allow(service)
          .to receive(:addresses_from_dns)
          .and_return([10, %w[foo bar]])
      end

      it 'refreshes the load balancer hosts' do
        expect(service)
          .to receive(:replace_hosts)
          .with(%w[foo bar])

        expect(service.refresh_if_necessary).to eq(10)
      end
    end

    context 'when a refresh is not necessary' do
      before do
        allow(service)
          .to receive(:addresses_from_load_balancer)
          .and_return(%w[localhost])

        allow(service)
          .to receive(:addresses_from_dns)
          .and_return([10, %w[localhost]])
      end

      it 'does not refresh the load balancer hosts' do
        expect(service)
          .not_to receive(:replace_hosts)

        expect(service.refresh_if_necessary).to eq(10)
      end
    end
  end

  describe '#replace_hosts' do
    let(:load_balancer) do
      Gitlab::Database::LoadBalancing::LoadBalancer.new(%w[foo])
    end

    before do
      allow(service)
        .to receive(:load_balancer)
        .and_return(load_balancer)
    end

    it 'replaces the hosts of the load balancer' do
      service.replace_hosts(%w[bar])

      expect(load_balancer.host_list.host_names).to eq(%w[bar])
    end

    it 'disconnects the old connections' do
      host = load_balancer.host_list.hosts.first

      allow(service)
        .to receive(:disconnect_timeout)
        .and_return(2)

      expect(host)
        .to receive(:disconnect!)
        .with(2)

      service.replace_hosts(%w[bar])
    end
  end

  describe '#addresses_from_dns' do
    it 'returns a TTL and ordered list of IP addresses' do
      res1 = double(:resource, address: '255.255.255.0', ttl: 90)
      res2 = double(:resource, address: '127.0.0.1', ttl: 90)

      allow(service.resolver)
        .to receive(:getresources)
        .with('foo', Resolv::DNS::Resource::IN::A)
        .and_return([res1, res2])

      expect(service.addresses_from_dns)
        .to eq([90, %w[127.0.0.1 255.255.255.0]])
    end
  end

  describe '#new_wait_time_for' do
    it 'returns the DNS TTL if greater than the default interval' do
      res = double(:resource, ttl: 90)

      expect(service.new_wait_time_for([res])).to eq(90)
    end

    it 'returns the default interval if greater than the DNS TTL' do
      res = double(:resource, ttl: 10)

      expect(service.new_wait_time_for([res])).to eq(60)
    end

    it 'returns the default interval if no resources are given' do
      expect(service.new_wait_time_for([])).to eq(60)
    end
  end

  describe '#addresses_from_load_balancer' do
    it 'returns the ordered host names of the load balancer' do
      load_balancer = Gitlab::Database::LoadBalancing::LoadBalancer.new(%w[b a])

      allow(service)
        .to receive(:load_balancer)
        .and_return(load_balancer)

      expect(service.addresses_from_load_balancer).to eq(%w[a b])
    end
  end
end
