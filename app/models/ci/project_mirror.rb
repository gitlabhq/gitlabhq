# frozen_string_literal: true

module Ci
  # This model represents a shadow table of the main database's projects table.
  # It allows us to navigate the project and namespace hierarchy on the ci database.
  class ProjectMirror < ApplicationRecord
    # Will be filled by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75517
  end
end
