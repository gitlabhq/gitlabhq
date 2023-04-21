# frozen_string_literal: true

module DesignManagement
  class Repository < ApplicationRecord
    include ::Gitlab::Utils::StrongMemoize

    belongs_to :project, inverse_of: :design_management_repository
    validates :project, presence: true, uniqueness: true

    # This is so that git_repo is initialized once `project` has been
    # set. If it is not set after intialization and saving the record
    # fails for some reason, the first call to `git_repo`` (initiated by
    # `delegate_missing_to`) will throw an error because project would
    # be missing.
    after_initialize :git_repo

    delegate_missing_to :git_repo

    def git_repo
      project ? GitRepository.new(project) : nil
    end
    strong_memoize_attr :git_repo
  end
end
