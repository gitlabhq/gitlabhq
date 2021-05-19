# frozen_string_literal: true

module Gitlab
  module Auth
    module Saml
      class Config
        class << self
          def options
            Gitlab::Auth::OAuth::Provider.config_for('saml')
          end

          def upstream_two_factor_authn_contexts
            options.args[:upstream_two_factor_authn_contexts]
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
end

Gitlab::Auth::Saml::Config.prepend_mod_with('Gitlab::Auth::Saml::Config')
