module EE
  module Gitlab
    module Auth
      module Saml
        module User
          extend ::Gitlab::Utils::Override

          override :find_user
          def find_user
            user = super

            if user_in_required_group?
              unblock_user(user, "in required group") if user.persisted? && user.blocked?
            elsif user.persisted?
              block_user(user, "not in required group") unless user.blocked?
            else
              user = nil
            end

            if user
              # Check if there is overlap between the user's groups and the external groups
              # setting then set user as external or internal.
              user.admin = !(auth_hash.groups & saml_config.admin_groups).empty? if admin_groups_enabled?
            end

            user
          end

          protected

          def block_user(user, reason)
            user.ldap_block
            log_user_changes(user, "#{reason}, blocking")
          end

          def unblock_user(user, reason)
            user.activate
            log_user_changes(user, "#{reason}, unblocking")
          end

          def log_user_changes(user, message)
            ::Gitlab::AppLogger.info(
              "SAML(#{auth_hash.provider}) account \"#{auth_hash.uid}\" #{message} " \
              "GitLab user \"#{user.name}\" (#{user.email})"
            )
          end

          def user_in_required_group?
            required_groups = saml_config.required_groups
            required_groups.empty? || !(auth_hash.groups & required_groups).empty?
          end

          def admin_groups_enabled?
            !saml_config.admin_groups.nil?
          end
        end
      end
    end
  end
end
