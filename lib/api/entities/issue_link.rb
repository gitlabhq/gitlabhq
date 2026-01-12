# frozen_string_literal: true

module API
  module Entities
    class IssueLink < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 1 }
      expose :source, as: :source_issue, using: ::API::Entities::IssueBasic
      expose :target, as: :target_issue, using: ::API::Entities::IssueBasic
      expose :link_type
    end
  end
end
