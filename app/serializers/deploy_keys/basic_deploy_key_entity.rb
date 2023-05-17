# frozen_string_literal: true

module DeployKeys
  class BasicDeployKeyEntity < Grape::Entity
    expose :id
    expose :user_id
    expose :title
    expose :fingerprint
    expose :fingerprint_sha256
    expose :destroyed_when_orphaned?, as: :destroyed_when_orphaned
    expose :almost_orphaned?, as: :almost_orphaned
    expose :created_at
    expose :expires_at
    expose :updated_at
    expose :can_edit
    expose :user, as: :owner, using: ::API::Entities::UserBasic, if: -> (_, opts) { can_read_owner?(opts) }

    private

    def can_edit
      Ability.allowed?(options[:user], :update_deploy_key, object) ||
        Ability.allowed?(options[:user], :update_deploy_keys_project, object.deploy_keys_project_for(options[:project]))
    end

    def can_read_owner?(opts)
      opts[:with_owner] && Ability.allowed?(options[:user], :read_user, object.user)
    end
  end
end
