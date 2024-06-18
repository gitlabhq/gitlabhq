# frozen_string_literal: true

module DeployKeys
  class BasicDeployKeyEntity < Grape::Entity
    include RequestAwareEntity

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
    expose :user, as: :owner, using: ::API::Entities::UserBasic, if: ->(_, opts) { can_read_owner?(opts) }
    expose :edit_path, if: ->(_, opts) { opts[:project] } do |deploy_key|
      edit_project_deploy_key_path(options[:project], deploy_key)
    end

    expose :enable_path, if: ->(_, opts) { opts[:project] } do |deploy_key|
      enable_project_deploy_key_path(options[:project], deploy_key)
    end

    expose :disable_path, if: ->(_, opts) { opts[:project] } do |deploy_key|
      disable_project_deploy_key_path(options[:project], deploy_key)
    end

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
