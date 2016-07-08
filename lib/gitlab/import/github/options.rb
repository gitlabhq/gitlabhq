module Gitlab
  module Import
    module Github
      class Options
        def endpoint
          client_options[:site]
        end

        def verify_ssl
          options.fetch(:verify_ssl, true)
        end

        private

        def client_options
          @client_options ||= options.fetch(:args, options)[:client_options]
        end

        def custom_options
          Gitlab.config.omniauth.providers.find { |provider| provider.name == 'github' }
        end

        def default_options
          OmniAuth::Strategies::GitHub.default_options
        end

        def options
          @options ||= (custom_options || default_options).deep_symbolize_keys
        end
      end
    end
  end
end
