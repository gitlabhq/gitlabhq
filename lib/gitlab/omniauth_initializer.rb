module Gitlab
  class OmniauthInitializer
    def initialize(devise_config)
      @devise_config = devise_config
    end

    def config
      @devise_config
    end

    def execute(providers)
      initialize_providers(providers)
    end

    private

    def initialize_providers(providers)
      providers.each do |provider|
        provider_arguments = []

        %w[app_id app_secret].each do |argument|
          provider_arguments << provider[argument] if provider[argument]
        end

        case provider['args']
        when Array
          # An Array from the configuration will be expanded.
          provider_arguments.concat provider['args']
        when Hash
          set_provider_specific_defaults(provider)

          # A Hash from the configuration will be passed as is.
          provider_arguments << provider['args'].symbolize_keys
        end

        config.omniauth provider['name'].to_sym, *provider_arguments
      end
    end

    def set_provider_specific_defaults(provider)
      # Add procs for handling SLO
      if provider['name'] == 'cas3'
        provider['args'][:on_single_sign_out] = cas3_signout_handler
      end

      if provider['name'] == 'authentiq'
        provider['args'][:remote_sign_out_handler] = authentiq_signout_handler
      end

      if provider['name'] == 'shibboleth'
        provider['args'][:fail_with_empty_uid] = true
      end
    end

    def cas3_signout_handler
      lambda do |request|
        ticket = request.params[:session_index]
        raise "Service Ticket not found." unless Gitlab::Auth::OAuth::Session.valid?(:cas3, ticket)

        Gitlab::Auth::OAuth::Session.destroy(:cas3, ticket)
        true
      end
    end

    def authentiq_signout_handler
      lambda do |request|
        authentiq_session = request.params['sid']
        if Gitlab::Auth::OAuth::Session.valid?(:authentiq, authentiq_session)
          Gitlab::Auth::OAuth::Session.destroy(:authentiq, authentiq_session)
          true
        else
          false
        end
      end
    end
  end
end
