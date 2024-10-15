# frozen_string_literal: true

module API
  module Entities
    class PullMirror < Grape::Entity
      expose :id, documentation: { type: 'integer', example: 101486 }
      expose :status, as: :update_status, documentation: { type: 'string', example: 'finished' }
      expose :url,
        documentation: { type: 'string',
                         example: 'https://*****:*****@gitlab.com/gitlab-org/security/gitlab.git' } do |import_state|
        import_state.project.safe_import_url
      end
      expose :last_error, documentation: { type: 'string', example: nil }
      expose :last_update_at, documentation: { type: 'dateTime', example: '2020-01-06T17:32:02.823Z' }
      expose :last_update_started_at, documentation: { type: 'dateTime', example: '2020-01-06T17:32:02.823Z' }
      expose :last_successful_update_at, documentation: { type: 'dateTime', example: '2020-01-06T17:32:02.823Z' }
      expose :enabled, documentation: { type: 'boolean', example: false }
      expose :mirror_trigger_builds, documentation: { type: 'boolean', example: false }
      expose :only_mirror_protected_branches, documentation: { type: 'boolean', example: false }
      expose :mirror_overwrites_diverged_branches, documentation: { type: 'boolean', example: false }
      expose :mirror_branch_regex, documentation: { type: 'string', example: 'branch_name' }

      delegate :project, to: :object
      delegate :mirror_trigger_builds, :only_mirror_protected_branches, :mirror_overwrites_diverged_branches,
        :mirror_branch_regex, to: :project

      def enabled
        object.project.mirror
      end
    end
  end
end
