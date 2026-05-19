# frozen_string_literal: true

module API
  module Entities
    class RelatedIssue < ::API::Entities::Issue
      expose :issue_link_id, documentation: { type: 'Integer', example: 1 }
      expose :issue_link_type, as: :link_type, documentation: { type: 'String', example: 'relates_to' }
      expose :issue_link_created_at, as: :link_created_at,
        documentation: { type: 'DateTime', example: '2022-01-31T15:10:44.988Z' }
      expose :issue_link_updated_at, as: :link_updated_at,
        documentation: { type: 'DateTime', example: '2022-01-31T15:10:44.988Z' }
    end
  end
end
