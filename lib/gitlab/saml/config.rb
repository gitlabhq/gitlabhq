module Gitlab
  module Saml
    class Config
      class << self
        def options
          Gitlab.config.omniauth.providers.find { |provider| provider.name == 'saml' }
        end

        def groups
          options[:groups_attribute]
        end

        def external_groups
          options[:external_groups]
        end

        def admin_groups
          options[:admin_groups]
        end
      end
    end
  end
end
