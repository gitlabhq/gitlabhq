# frozen_string_literal: true

module QA
  module Vendor
    module Smocker
      class SmockerApi
        include Scenario::Actable
        include Support::API

        DEFAULT_MOCK = <<~YAML
          - request:
              method: POST
              path: /default
            response:
              headers:
                Content-Type: application/json
              body: '{}'
        YAML

        def initialize(host:, public_port: 8080, admin_port: 8081, tls: false)
          @host = host
          @public_port = public_port
          @admin_port = admin_port
          @scheme = tls ? "https" : "http"
        end

        # @return [String] Base url of mock endpoint
        def base_url
          @base_url ||= "#{scheme}://#{host}:#{public_port}"
        end

        # @return [String] Url of admin endpoint
        def admin_url
          @admin_url ||= "#{scheme}://#{host}:#{admin_port}"
        end

        # @param endpoint [String] path for mock endpoint
        # @return [String] url for mock endpoint
        def url(endpoint = 'default')
          "#{base_url}/#{endpoint}"
        end

        # Waits for the smocker server to be ready
        #
        # @param wait [Integer] wait duration for smocker readiness
        def wait_for_ready(wait: 10)
          Support::Waiter.wait_until(max_duration: wait, sleep_interval: 1, log: false) do
            ready?
          end
        end

        # Is smocker server ready for interaction?
        #
        # @return [Boolean]
        def ready?
          QA::Runtime::Logger.debug 'Checking Smocker readiness'
          get("#{admin_url}/version")
          true
          # rescuing StandardError because RestClient::ExceptionWithResponse isn't propagating
        rescue StandardError => e
          QA::Runtime::Logger.debug "Smocker not ready yet \n #{e}"
          false
        end

        # Clears mocks and history
        #
        # @param force [Boolean] remove locked mocks?
        # @return [Boolean] reset was successful?
        def reset(force: true)
          response = post("#{admin_url}/reset?force=#{force}", {}.to_json)
          parse_body(response)['message'] == 'Reset successful'
        end

        # Fetches an active session id from a name
        #
        # @param name [String] the name of the session
        # @return [String] the unique session id
        def get_session_id(name)
          sessions = parse_body get("#{admin_url}/sessions/summary")
          current = sessions.find do |session|
            session[:name] == name
          end
          current&.dig(:id)
        end

        # Registers a mock to Smocker
        # If a session name is provided, the mock will register to that session
        # https://smocker.dev/technical-documentation/mock-definition.html
        #
        # @param yaml [String] the yaml representing the mock
        # @param session [String] the session name for the mock
        def register(yaml = DEFAULT_MOCK, session: nil)
          query_params = build_params(session: session)
          url = "#{admin_url}/mocks?#{query_params}"
          headers = { 'Content-Type' => 'application/x-yaml' }
          response = post(url, yaml, headers: headers)
          parse_body(response)
        end

        # Fetches call history for a mock
        #
        # @param session_name [String] the session name for the mock
        # @return [Array<HistoryResponse>]
        def history(session_name = nil)
          query_params = session_name ? build_params(session: get_session_id(session_name)) : ''
          response = get("#{admin_url}/history?#{query_params}")
          body = parse_body(response)

          raise body[:message] unless body.is_a?(Array)

          body.map do |entry|
            HistoryResponse.new(entry)
          end
        end

        # Fetch session verify response
        #
        # @param [String] session_name
        # @return [VerifyResponse]
        def verify(session_name = nil)
          payload = { session: session_name ? get_session_id(session_name) : nil }
          response = post("#{admin_url}/sessions/verify", payload)

          VerifyResponse.new(parse_body(response))
        end

        # Returns a stringfied version of the Smocker history
        #
        # @param session_name [String] the session name for the mock
        # @return [String] stringified event payloads
        def stringified_history(session_name = nil)
          history(session_name).map(&:payload).join("\n")
        end

        private

        attr_reader :host, :public_port, :admin_port, :scheme

        def build_params(**args)
          args.each_with_object([]) do |(k, v), memo|
            memo << "#{k}=#{v}" if v
          end.join("&")
        end
      end
    end
  end
end
