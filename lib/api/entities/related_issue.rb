# frozen_string_literal: true

module API
  module Entities
    class RelatedIssue < ::API::Entities::Issue
      expose :issue_link_id
      expose :issue_link_type, as: :link_type
      expose :issue_link_created_at, as: :link_created_at
      expose :issue_link_updated_at, as: :link_updated_at
    end
  end
end
