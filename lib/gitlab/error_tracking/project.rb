# frozen_string_literal: true

# This should be in the ErrorTracking namespace. For more details, see:
# https://gitlab.com/gitlab-org/gitlab/-/issues/323342
module Gitlab
  module ErrorTracking
    class Project
      include ActiveModel::Model

      ACCESSORS = [
        :id, :name, :status, :slug, :organization_name,
        :organization_id, :organization_slug
      ].freeze

      attr_accessor(*ACCESSORS)
    end
  end
end
