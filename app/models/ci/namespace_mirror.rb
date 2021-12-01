# frozen_string_literal: true

module Ci
  # This model represents a record in a shadow table of the main database's namespaces table.
  # It allows us to navigate the namespace hierarchy on the ci database without resorting to a JOIN.
  class NamespaceMirror < ApplicationRecord
    # Will be filled by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75517
  end
end
