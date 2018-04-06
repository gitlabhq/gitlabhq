module Gitlab
  module Auth
    module GroupSaml
      class Config < Gitlab::Auth::Saml::Config
        def self.options
          {}
        end

        def self.enabled?
          Gitlab::Auth::OAuth::Provider.enabled?(:group_saml)
        end
      end
    end
  end
end
