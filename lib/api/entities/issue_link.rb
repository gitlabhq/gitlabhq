# frozen_string_literal: true

module API
  module Entities
    class IssueLink < Grape::Entity
      expose :source, as: :source_issue, using: ::API::Entities::IssueBasic
      expose :target, as: :target_issue, using: ::API::Entities::IssueBasic
      expose :link_type
    end
  end
end
