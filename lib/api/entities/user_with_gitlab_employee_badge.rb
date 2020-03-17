# frozen_string_literal: true

module API
  module Entities
    class UserWithGitlabEmployeeBadge < UserBasic
      expose :gitlab_employee?, as: :is_gitlab_employee, if: ->(user, options) { ::Feature.enabled?(:gitlab_employee_badge) && user.gitlab_employee? }
    end
  end
end
