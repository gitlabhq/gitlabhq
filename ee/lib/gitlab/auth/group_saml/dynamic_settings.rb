module Gitlab
  module Auth
    module GroupSaml
      class DynamicSettings
        include Enumerable

        delegate :each, :keys, :[], to: :settings

        def initialize(saml_provider)
          @saml_provider = saml_provider
        end

        def settings
          @settings ||= configured_settings.merge(default_settings)
        end

        private

        def configured_settings
          @saml_provider&.settings || {}
        end

        def default_settings
          {
            idp_sso_target_url_runtime_params: { redirect_to: :RelayState }
          }
        end
      end
    end
  end
end
