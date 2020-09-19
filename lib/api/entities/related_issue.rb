# frozen_string_literal: true

module API
  module Entities
    class RelatedIssue < ::API::Entities::Issue
      expose :issue_link_id
      expose :issue_link_type, as: :link_type
    end
  end
end
