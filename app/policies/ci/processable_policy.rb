# frozen_string_literal: true

module Ci
  module ProcessablePolicy
    extend ActiveSupport::Concern

    included do
      condition(:archived, scope: :subject) do
        @subject.archived?(log: true)
      end

      rule { archived }.policy do
        # We exclude `update_build` because it's used as an internal abstraction that is used to
        # influence other permissions, like `erase_build`, etc.
        # Preventing `update_build` would cause other permissions like `erase_build` to be prevented.
        user_facing_update_permissions = ::ProjectPolicy::UPDATE_JOB_PERMISSIONS - [:update_build]
        prevent(*user_facing_update_permissions)
      end
    end
  end
end
