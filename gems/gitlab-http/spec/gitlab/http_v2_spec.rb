# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HTTP_V2, feature_category: :shared do
  context 'when allow_local_requests' do
    it 'sends the request to the correct URI' do
      stub_full_request('https://example.org:8080', ip_address: '8.8.8.8').to_return(status: 200)

      described_class.get('https://example.org:8080', allow_local_requests: false)

      expect(WebMock).to have_requested(:get, 'https://8.8.8.8:8080').once
    end
  end

  context 'when not allow_local_requests' do
    it 'sends the request to the correct URI' do
      stub_full_request('https://example.org:8080')

      described_class.get('https://example.org:8080', allow_local_requests: true)

      expect(WebMock).to have_requested(:get, 'https://8.8.8.9:8080').once
    end
  end

  context 'when reading the response is too slow' do
    before(:all) do
      # Override Net::HTTP to add a delay between sending each response chunk
      mocked_http = Class.new(Net::HTTP) do
        def request(*)
          super do |response|
            response.instance_eval do
              def read_body(*)
                mock_stream = @body.split(' ')
                mock_stream.each do |fragment|
                  sleep 0.002.seconds

                  yield fragment if block_given?
                end

                @body
              end
            end

            yield response if block_given?

            response
          end
        end
      end

      @original_net_http = Net.send(:remove_const, :HTTP)
      @webmock_net_http = WebMock::HttpLibAdapters::NetHttpAdapter.instance_variable_get(:@webMockNetHTTP)

      Net.send(:const_set, :HTTP, mocked_http)
      WebMock::HttpLibAdapters::NetHttpAdapter.instance_variable_set(:@webMockNetHTTP, mocked_http)

      # Reload Gitlab::NetHttpAdapter
      described_class.send(:remove_const, :NetHttpAdapter)
      load "gitlab/http_v2/net_http_adapter.rb"
    end

    before do
      stub_const("#{described_class}::Client::DEFAULT_READ_TOTAL_TIMEOUT", 0.001.seconds)

      WebMock.stub_request(:post, /.*/).to_return do
        { body: "chunk-1 chunk-2", status: 200 }
      end
    end

    after(:all) do
      Net.send(:remove_const, :HTTP)
      Net.send(:const_set, :HTTP, @original_net_http) # rubocop:disable RSpec/InstanceVariable
      WebMock::HttpLibAdapters::NetHttpAdapter.instance_variable_set(:@webMockNetHTTP, @webmock_net_http) # rubocop:disable RSpec/InstanceVariable

      # Reload Gitlab::NetHttpAdapter
      described_class.send(:remove_const, :NetHttpAdapter)
      load "gitlab/http_v2/net_http_adapter.rb"
    end

    let(:options) { {} }

    subject(:request_slow_responder) { described_class.post('http://example.org', **options) }

    it 'raises an error' do
      expect do
        request_slow_responder
      end.to raise_error(Gitlab::HTTP_V2::ReadTotalTimeout,
        /Request timed out after ?([0-9]*[.])?[0-9]+ seconds/)
    end

    context 'and timeout option is greater than DEFAULT_READ_TOTAL_TIMEOUT' do
      let(:options) { { timeout: 10.seconds } }

      it 'does not raise an error' do
        expect { request_slow_responder }.not_to raise_error
      end
    end

    context 'and stream_body option is truthy' do
      let(:options) { { stream_body: true } }

      it 'does not raise an error' do
        expect { request_slow_responder }.not_to raise_error
      end
    end
  end

  it 'calls a block' do
    WebMock.stub_request(:post, /.*/)

    expect { |b| described_class.post('http://example.org', &b) }.to yield_with_args
  end

  describe 'allow_local_requests' do
    before do
      WebMock.stub_request(:get, /.*/).to_return(status: 200, body: 'Success')
    end

    context 'when it is disabled' do
      it 'deny requests to localhost' do
        expect do
          described_class.get('http://localhost:3003', allow_local_requests: false)
        end.to raise_error(Gitlab::HTTP_V2::BlockedUrlError)
      end

      it 'deny requests to private network' do
        expect do
          described_class.get('http://192.168.1.2:3003', allow_local_requests: false)
        end.to raise_error(Gitlab::HTTP_V2::BlockedUrlError)
      end

      context 'if allow_local_requests set to true' do
        it 'override the global value and allow requests to localhost or private network' do
          stub_full_request('http://localhost:3003')

          expect { described_class.get('http://localhost:3003', allow_local_requests: true) }.not_to raise_error
        end
      end
    end

    context 'when it is enabled' do
      it 'allow requests to localhost' do
        stub_full_request('http://localhost:3003')

        expect { described_class.get('http://localhost:3003', allow_local_requests: true) }.not_to raise_error
      end

      it 'allow requests to private network' do
        expect { described_class.get('http://192.168.1.2:3003', allow_local_requests: true) }.not_to raise_error
      end

      context 'if allow_local_requests set to false' do
        it 'override the global value and ban requests to localhost or private network' do
          expect do
            described_class.get('http://localhost:3003',
              allow_local_requests: false)
          end.to raise_error(Gitlab::HTTP_V2::BlockedUrlError)
        end
      end
    end
  end

  describe 'handle redirect loops' do
    before do
      stub_full_request("http://example.org", method: :any)
        .to_raise(HTTParty::RedirectionTooDeep.new("Redirection Too Deep"))
    end

    it 'handles GET requests' do
      expect { described_class.get('http://example.org') }.to raise_error(Gitlab::HTTP_V2::RedirectionTooDeep)
    end

    it 'handles POST requests' do
      expect { described_class.post('http://example.org') }.to raise_error(Gitlab::HTTP_V2::RedirectionTooDeep)
    end

    it 'handles PUT requests' do
      expect { described_class.put('http://example.org') }.to raise_error(Gitlab::HTTP_V2::RedirectionTooDeep)
    end

    it 'handles DELETE requests' do
      expect { described_class.delete('http://example.org') }.to raise_error(Gitlab::HTTP_V2::RedirectionTooDeep)
    end

    it 'handles HEAD requests' do
      expect { described_class.head('http://example.org') }.to raise_error(Gitlab::HTTP_V2::RedirectionTooDeep)
    end
  end

  describe 'setting default timeouts' do
    let(:default_timeout_options) { described_class::Client::DEFAULT_TIMEOUT_OPTIONS }

    before do
      stub_full_request('http://example.org', method: :any)
    end

    context 'when no timeouts are set' do
      it 'sets default open and read and write timeouts' do
        expect(described_class::Client).to receive(:httparty_perform_request).with(
          Net::HTTP::Get, 'http://example.org', default_timeout_options
        ).and_call_original

        described_class.get('http://example.org')
      end
    end

    context 'when :timeout is set' do
      it 'does not set any default timeouts' do
        expect(described_class::Client).to receive(:httparty_perform_request).with(
          Net::HTTP::Get, 'http://example.org', { timeout: 1 }
        ).and_call_original

        described_class.get('http://example.org', timeout: 1)
      end
    end

    context 'when :open_timeout is set' do
      it 'only sets default read and write timeout' do
        expect(described_class::Client).to receive(:httparty_perform_request).with(
          Net::HTTP::Get, 'http://example.org', default_timeout_options.merge(open_timeout: 1)
        ).and_call_original

        described_class.get('http://example.org', open_timeout: 1)
      end
    end

    context 'when :read_timeout is set' do
      it 'only sets default open and write timeout' do
        expect(described_class::Client).to receive(:httparty_perform_request).with(
          Net::HTTP::Get, 'http://example.org', default_timeout_options.merge(read_timeout: 1)
        ).and_call_original

        described_class.get('http://example.org', read_timeout: 1)
      end
    end

    context 'when :write_timeout is set' do
      it 'only sets default open and read timeout' do
        expect(described_class::Client).to receive(:httparty_perform_request).with(
          Net::HTTP::Put, 'http://example.org', default_timeout_options.merge(write_timeout: 1)
        ).and_call_original

        described_class.put('http://example.org', write_timeout: 1)
      end
    end
  end

  describe 'logging response size' do
    context 'when GITLAB_LOG_DECOMPRESSED_RESPONSE_BYTESIZE is not set' do
      before do
        stub_full_request('http://example.org', method: :any).to_return(status: 200, body: 'hello world')
      end

      it 'does not log response size' do
        expect(described_class.configuration)
          .not_to receive(:log_with_level)

        described_class.get('http://example.org')
      end

      context 'when the request is async' do
        it 'does not log response size' do
          expect(described_class.configuration)
            .not_to receive(:log_with_level)

          described_class.get('http://example.org', async: true).execute.value
        end
      end
    end

    context 'when GITLAB_LOG_DECOMPRESSED_RESPONSE_BYTESIZE is set' do
      before do
        described_class::Client.remove_instance_variable(:@should_log_response_size)
        stub_env('GITLAB_LOG_DECOMPRESSED_RESPONSE_BYTESIZE', 5)
        stub_full_request('http://example.org', method: :any).to_return(status: 200, body: 'hello world')
      end

      it 'logs the response size' do
        expect(described_class.configuration)
          .to receive(:log_with_level)
          .with(:debug, { message: "gitlab/http: response size", size: 11 })
          .once

        described_class.get('http://example.org')
      end

      context 'when the request is async' do
        it 'logs response size' do
          expect(described_class.configuration)
            .to receive(:log_with_level)
            .with(:debug, { message: "gitlab/http: response size", size: 11 })
            .once

          described_class.get('http://example.org', async: true).execute.value
        end
      end

      context 'and the response size is smaller than the limit' do
        before do
          stub_env('GITLAB_LOG_DECOMPRESSED_RESPONSE_BYTESIZE', 50)
        end

        it 'does not log the response size' do
          expect(described_class.configuration)
            .not_to receive(:log_with_level)

          described_class.get('http://example.org')
        end
      end
    end
  end

  describe '.try_get' do
    let(:path) { 'http://example.org' }
    let(:default_timeout_options) { described_class::Client::DEFAULT_TIMEOUT_OPTIONS }

    let(:extra_log_info_proc) do
      proc do |error, url, options|
        { klass: error.class, url: url, options: options }
      end
    end

    let(:request_options) do
      {
        **default_timeout_options,
        verify: false,
        basic_auth: { username: 'user', password: 'pass' }
      }
    end

    described_class::HTTP_ERRORS.each do |exception_class|
      context "with #{exception_class}" do
        let(:klass) { exception_class }

        context 'with path' do
          before do
            expect(described_class::Client).to receive(:httparty_perform_request) # rubocop:disable RSpec/ExpectInHook
              .with(Net::HTTP::Get, path, default_timeout_options)
              .and_raise(klass)
          end

          it 'handles requests without extra_log_info' do
            expect(described_class.configuration)
              .to receive(:log_exception)
              .with(instance_of(klass), {})

            expect(described_class.try_get(path)).to be_nil
          end

          it 'handles requests with extra_log_info as hash' do
            expect(described_class.configuration)
              .to receive(:log_exception)
              .with(instance_of(klass), { a: :b })

            expect(described_class.try_get(path, extra_log_info: { a: :b })).to be_nil
          end

          it 'handles requests with extra_log_info as proc' do
            expect(described_class.configuration)
              .to receive(:log_exception)
              .with(instance_of(klass), { url: path, klass: klass, options: {} })

            expect(described_class.try_get(path, extra_log_info: extra_log_info_proc)).to be_nil
          end
        end

        context 'with path and options' do
          before do
            expect(described_class::Client).to receive(:httparty_perform_request) # rubocop:disable RSpec/ExpectInHook
              .with(Net::HTTP::Get, path, request_options)
              .and_raise(klass)
          end

          it 'handles requests without extra_log_info' do
            expect(described_class.configuration)
              .to receive(:log_exception)
              .with(instance_of(klass), {})

            expect(described_class.try_get(path, request_options)).to be_nil
          end

          it 'handles requests with extra_log_info as hash' do
            expect(described_class.configuration)
              .to receive(:log_exception)
              .with(instance_of(klass), { a: :b })

            expect(described_class.try_get(path, **request_options, extra_log_info: { a: :b })).to be_nil
          end

          it 'handles requests with extra_log_info as proc' do
            expect(described_class.configuration)
              .to receive(:log_exception)
              .with(instance_of(klass), { klass: klass, url: path, options: request_options })

            expect(described_class.try_get(path, **request_options, extra_log_info: extra_log_info_proc)).to be_nil
          end
        end

        context 'with path, options, and block' do
          let(:block) do
            proc {}
          end

          before do
            expect(described_class::Client).to receive(:httparty_perform_request) # rubocop:disable RSpec/ExpectInHook
              .with(Net::HTTP::Get, path, request_options, &block)
              .and_raise(klass)
          end

          it 'handles requests without extra_log_info' do
            expect(described_class.configuration)
              .to receive(:log_exception)
              .with(instance_of(klass), {})

            expect(described_class.try_get(path, request_options, &block)).to be_nil
          end

          it 'handles requests with extra_log_info as hash' do
            expect(described_class.configuration)
              .to receive(:log_exception)
              .with(instance_of(klass), { a: :b })

            expect(described_class.try_get(path, **request_options, extra_log_info: { a: :b }, &block)).to be_nil
          end

          it 'handles requests with extra_log_info as proc' do
            expect(described_class.configuration)
              .to receive(:log_exception)
              .with(instance_of(klass), { klass: klass, url: path, options: request_options })

            expect(
              described_class.try_get(path, **request_options, extra_log_info: extra_log_info_proc, &block)
            ).to be_nil
          end
        end
      end
    end
  end

  describe 'silent mode', feature_category: :geo_replication do
    before do
      stub_full_request("http://example.org", method: :any)
    end

    context 'when silent mode is enabled' do
      let(:silent_mode) { true }

      it 'allows GET requests' do
        expect { described_class.get('http://example.org', silent_mode_enabled: silent_mode) }.not_to raise_error
      end

      it 'allows HEAD requests' do
        expect { described_class.head('http://example.org', silent_mode_enabled: silent_mode) }.not_to raise_error
      end

      it 'allows OPTIONS requests' do
        expect { described_class.options('http://example.org', silent_mode_enabled: silent_mode) }.not_to raise_error
      end

      it 'blocks POST requests' do
        expect do
          described_class.post('http://example.org', silent_mode_enabled: silent_mode)
        end.to raise_error(Gitlab::HTTP_V2::SilentModeBlockedError)
      end

      it 'blocks PUT requests' do
        expect do
          described_class.put('http://example.org', silent_mode_enabled: silent_mode)
        end.to raise_error(Gitlab::HTTP_V2::SilentModeBlockedError)
      end

      it 'blocks DELETE requests' do
        expect do
          described_class.delete('http://example.org', silent_mode_enabled: silent_mode)
        end.to raise_error(Gitlab::HTTP_V2::SilentModeBlockedError)
      end

      it 'logs blocked requests' do
        expect(described_class.configuration).to receive(:silent_mode_log_info).with(
          "Outbound HTTP request blocked", 'Net::HTTP::Post'
        )

        expect do
          described_class.post('http://example.org', silent_mode_enabled: silent_mode)
        end.to raise_error(Gitlab::HTTP_V2::SilentModeBlockedError)
      end
    end

    context 'when silent mode is disabled' do
      let(:silent_mode) { false }

      it 'allows GET requests' do
        expect { described_class.get('http://example.org', silent_mode_enabled: silent_mode) }.not_to raise_error
      end

      it 'allows HEAD requests' do
        expect { described_class.head('http://example.org', silent_mode_enabled: silent_mode) }.not_to raise_error
      end

      it 'allows OPTIONS requests' do
        expect { described_class.options('http://example.org', silent_mode_enabled: silent_mode) }.not_to raise_error
      end

      it 'blocks POST requests' do
        expect { described_class.post('http://example.org', silent_mode_enabled: silent_mode) }.not_to raise_error
      end

      it 'blocks PUT requests' do
        expect { described_class.put('http://example.org', silent_mode_enabled: silent_mode) }.not_to raise_error
      end

      it 'blocks DELETE requests' do
        expect { described_class.delete('http://example.org', silent_mode_enabled: silent_mode) }.not_to raise_error
      end
    end
  end

  context 'when options[:async] is true' do
    context 'when it is a valid request' do
      before do
        stub_full_request('http://example.org', method: :any).to_return(status: 200, body: 'hello world')
      end

      it 'returns a LazyResponse' do
        result = described_class.get('http://example.org', async: true)

        expect(result).to be_a(Gitlab::HTTP_V2::LazyResponse)
        expect(result.state).to eq(:unscheduled)

        expect(result.execute).to be_a(Gitlab::HTTP_V2::LazyResponse)
        expect(result.wait).to be_a(Gitlab::HTTP_V2::LazyResponse)

        expect(result.value).to be_a(HTTParty::Response)
        expect(result.value.body).to eq('hello world')
      end
    end

    context 'when the URL is denied' do
      let(:url) { 'http://localhost:3003' }
      let(:error_class) { Gitlab::HTTP_V2::BlockedUrlError }
      let(:opts) { {} }

      let(:result) do
        described_class.get(url, allow_local_requests: false, async: true, **opts)
      end

      it 'returns a LazyResponse with error value' do
        expect(result).to be_a(Gitlab::HTTP_V2::LazyResponse)

        expect { result.execute.value }.to raise_error(error_class)
      end

      it 'logs the exception' do
        expect(described_class.configuration)
          .to receive(:log_exception)
          .with(instance_of(error_class), {})

        expect { result.execute.value }.to raise_error(error_class)
      end

      context 'with extra_log_info as hash' do
        let(:opts) { { extra_log_info: { a: :b } } }

        it 'handles the request' do
          expect(described_class.configuration)
            .to receive(:log_exception)
            .with(instance_of(error_class), { a: :b })

          expect { result.execute.value }.to raise_error(error_class)
        end
      end

      context 'with extra_log_info as proc' do
        let(:extra_log_info) do
          proc do |error, url, options|
            { klass: error.class, url: url, options: options }
          end
        end

        let(:opts) { { extra_log_info: extra_log_info } }

        it 'handles the request' do
          expect(described_class.configuration)
            .to receive(:log_exception)
            .with(instance_of(error_class), { url: url, klass: error_class, options: { allow_local_requests: false } })

          expect { result.execute.value }.to raise_error(error_class)
        end
      end
    end
  end

  context 'when options[:async] and options[:stream_body] are true' do
    before do
      stub_full_request('http://example.org', method: :any)
    end

    it 'raises an ArgumentError' do
      expect { described_class.get('http://example.org', async: true, stream_body: true) }
        .to raise_error(ArgumentError, '`async` cannot be used with `stream_body` or `silent_mode_enabled`')
    end
  end

  context 'when options[:async] and options[:silent_mode_enabled] are true' do
    before do
      stub_full_request('http://example.org', method: :any)
    end

    it 'raises an ArgumentError' do
      expect { described_class.get('http://example.org', async: true, silent_mode_enabled: true) }
        .to raise_error(ArgumentError, '`async` cannot be used with `stream_body` or `silent_mode_enabled`')
    end
  end
end
