# frozen_string_literal: true

module API
  module Entities
    class PullMirror < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 101486 }
      expose :status, as: :update_status, documentation: { type: 'String', example: 'finished' }
      expose :url,
        documentation: { type: 'String',
                         example: 'https://*****:*****@gitlab.com/gitlab-org/security/gitlab.git' } do |import_state|
        import_state.project.safe_import_url
      end
      expose :last_error, documentation: { type: 'String', example: nil }
      expose :last_update_at, documentation: { type: 'DateTime', example: '2020-01-06T17:32:02.823Z' }
      expose :last_update_started_at, documentation: { type: 'DateTime', example: '2020-01-06T17:32:02.823Z' }
      expose :last_successful_update_at, documentation: { type: 'DateTime', example: '2020-01-06T17:32:02.823Z' }
      expose :enabled, documentation: { type: 'Boolean', example: false }
      expose :mirror_trigger_builds, documentation: { type: 'Boolean', example: false }
      expose :only_mirror_protected_branches, documentation: { type: 'Boolean', example: false }
      expose :mirror_overwrites_diverged_branches, documentation: { type: 'Boolean', example: false }
      expose :mirror_branch_regex, documentation: { type: 'String', example: 'branch_name' }

      delegate :project, to: :object
      delegate :mirror_trigger_builds, :only_mirror_protected_branches, :mirror_overwrites_diverged_branches,
        :mirror_branch_regex, to: :project

      def enabled
        object.project.mirror
      end
    end
  end
end
