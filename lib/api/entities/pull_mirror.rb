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
    end
  end
end
