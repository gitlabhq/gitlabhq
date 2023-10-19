# frozen_string_literal: true

require 'spec_helper'
require 'net/http'

RSpec.describe 'Net::HTTP patch proxy user and password encoding', feature_category: :shared do
  let(:net_http) { Net::HTTP.new('hostname.example') }

  before do
    # This file can be removed once Ruby 3.0 is no longer supported:
    # https://gitlab.com/gitlab-org/gitlab/-/issues/396223
    skip if Gem::Version.new(Net::HTTP::VERSION) >= Gem::Version.new('0.2.0')
  end

  describe '#proxy_user' do
    subject { net_http.proxy_user }

    it { is_expected.to eq(nil) }

    context 'with http_proxy env' do
      let(:http_proxy) { 'http://proxy.example:8000' }

      before do
        stub_env('http_proxy', http_proxy)
      end

      it { is_expected.to eq(nil) }

      context 'and user:password authentication' do
        let(:http_proxy) { 'http://Y%5CX:R%25S%5D%20%3FX@proxy.example:8000' }

        context 'when on multiuser safe platform' do
          # linux, freebsd, darwin are considered multi user safe platforms
          # See https://github.com/ruby/net-http/blob/v0.1.1/lib/net/http.rb#L1174-L1178

          before do
            allow(net_http).to receive(:environment_variable_is_multiuser_safe?).and_return(true)
          end

          it { is_expected.to eq 'Y\\X' }
        end

        context 'when not on multiuser safe platform' do
          before do
            allow(net_http).to receive(:environment_variable_is_multiuser_safe?).and_return(false)
          end

          it { is_expected.to be_nil }
        end
      end
    end
  end

  describe '#proxy_pass' do
    subject { net_http.proxy_pass }

    it { is_expected.to eq(nil) }

    context 'with http_proxy env' do
      let(:http_proxy) { 'http://proxy.example:8000' }

      before do
        stub_env('http_proxy', http_proxy)
      end

      it { is_expected.to eq(nil) }

      context 'and user:password authentication' do
        let(:http_proxy) { 'http://Y%5CX:R%25S%5D%20%3FX@proxy.example:8000' }

        context 'when on multiuser safe platform' do
          # linux, freebsd, darwin are considered multi user safe platforms
          # See https://github.com/ruby/net-http/blob/v0.1.1/lib/net/http.rb#L1174-L1178

          before do
            allow(net_http).to receive(:environment_variable_is_multiuser_safe?).and_return(true)
          end

          it { is_expected.to eq 'R%S] ?X' }
        end

        context 'when not on multiuser safe platform' do
          before do
            allow(net_http).to receive(:environment_variable_is_multiuser_safe?).and_return(false)
          end

          it { is_expected.to be_nil }
        end
      end
    end
  end
end
