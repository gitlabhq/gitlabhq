# frozen_string_literal: true

module Gitlab
  module PolicyStore
    module Roles
      # GitLab project/group roles (available for non-deployment triggers)
      DEVELOPER = 'developer'
      MAINTAINER = 'maintainer'
      OWNER = 'owner'

      GITLAB_ROLES = [
        { id: DEVELOPER, name: 'Developer' }.freeze,
        { id: MAINTAINER, name: 'Maintainer' }.freeze,
        { id: OWNER, name: 'Owner' }.freeze
      ].freeze

      # CD-specific roles (only available for deployment triggers)
      DEPLOYMENT_OBSERVER = 'deployment_observer'
      RELEASE_MANAGER = 'release_manager'

      CD_ROLES = [
        { id: DEPLOYMENT_OBSERVER, name: 'Deployment Observer' }.freeze,
        { id: RELEASE_MANAGER, name: 'Release Manager' }.freeze
      ].freeze

      # Triggers that support CD roles - explicitly listed to avoid accidentally
      # granting CD roles to future non-deployment trigger types
      DEPLOYMENT_TRIGGERS = %w[deployment_requested environment_advanced deployment_promoted].freeze

      # Memoized ID arrays to avoid repeated allocations during validation
      GITLAB_ROLE_IDS = GITLAB_ROLES.map { |r| r[:id] }.freeze
      CD_ROLE_IDS = CD_ROLES.map { |r| r[:id] }.freeze
      ALL_ROLE_IDS = (GITLAB_ROLE_IDS + CD_ROLE_IDS).freeze

      def self.for_trigger(trigger_type)
        if DEPLOYMENT_TRIGGERS.include?(trigger_type)
          CD_ROLES
        else
          GITLAB_ROLES
        end
      end

      def self.gitlab_role_ids
        GITLAB_ROLE_IDS
      end

      def self.cd_role_ids
        CD_ROLE_IDS
      end

      def self.all_role_ids
        ALL_ROLE_IDS
      end
    end
  end
end
