module EE
  module AuditEventService
    def for_member(member)
      action = @details[:action]
      old_access_level = @details[:old_access_level]
      author_name = @author.name
      user_id = member.id
      user_name = member.user ? member.user.name : 'Deleted User'

      @details =
        case action
        when :destroy
          {
            remove: "user_access",
            author_name: author_name,
            target_id: user_id,
            target_type: "User",
            target_details: user_name
          }
        when :create
          {
            add: "user_access",
            as: ::Gitlab::Access.options_with_owner.key(member.access_level.to_i),
            author_name: author_name,
            target_id: user_id,
            target_type: "User",
            target_details: user_name
          }
        when :update, :override
          {
            change: "access_level",
            from: old_access_level,
            to: member.human_access,
            author_name: author_name,
            target_id: user_id,
            target_type: "User",
            target_details: user_name
          }
        end

      self
    end

    def for_deploy_key(key_title)
      action = @details[:action]
      author_name = @author.name

      @details =
        case action
        when :destroy
          {
            remove: "deploy_key",
            author_name: author_name,
            target_id: key_title,
            target_type: "DeployKey",
            target_details: key_title
          }
        when :create
          {
            add: "deploy_key",
            author_name: author_name,
            target_id: key_title,
            target_type: "DeployKey",
            target_details: key_title
          }
        end

      self
    end

    def security_event
      if admin_audit_log_enabled?
        add_security_event_admin_details!

        return super
      end

      super if audit_events_enabled?
    end

    def add_security_event_admin_details!
      @details.merge!(ip_address: @author.current_sign_in_ip,
                      entity_path: @entity.full_path)
    end

    def audit_events_enabled?
      return true unless @entity.respond_to?(:feature_available?)

      @entity.feature_available?(:audit_events)
    end

    def admin_audit_log_enabled?
      License.feature_available?(:admin_audit_log)
    end
  end
end
