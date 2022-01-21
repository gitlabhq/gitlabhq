# frozen_string_literal: true

module API
  module Entities
    class UserSafe < Grape::Entity
      expose :id, :username
      expose :name do |user|
        next user.name unless user.project_bot?

        next user.name if options[:current_user]&.can?(:read_project, user.projects.first)

        # If the requester does not have permission to read the project bot name,
        # the API returns an arbitrary string. UI changes will be addressed in a follow up issue:
        # https://gitlab.com/gitlab-org/gitlab/-/issues/346058
        '****'
      end
    end
  end
end
