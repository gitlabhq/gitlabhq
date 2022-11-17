# frozen_string_literal: true

module API
  module Entities
    class UserAssociationsCount < Grape::Entity
      expose :groups_count do |user|
        user.groups.size
      end

      expose :projects_count do |user|
        user.projects.size
      end

      expose :issues_count do |user|
        user.issues.size
      end

      expose :merge_requests_count do |user|
        user.merge_requests.size
      end
    end
  end
end
