# frozen_string_literal: true

module Gitlab
  class RepositorySizeErrorMessage
    include ActiveSupport::NumberHelper

    delegate :current_size, :limit, :exceeded_size, :additional_repo_storage_available?, to: :@checker

    # @param checker [RepositorySizeChecker]
    def initialize(checker)
      @checker = checker
    end

    def commit_error
      "Your changes could not be committed, #{base_message}"
    end

    def merge_error
      "This merge request cannot be merged, #{base_message}"
    end

    def push_error
      "Your push to this repository cannot be completed #{base_message}. #{more_info_message}"
    end

    def new_changes_error
      "Your push to this repository cannot be completed as it would exceed the allocated storage for your project. #{more_info_message}"
    end

    def more_info_message
      'Contact your GitLab administrator for more information.'
    end

    def above_size_limit_message
      "The size of this repository (#{formatted(current_size)}) exceeds the limit of #{formatted(limit)} by #{formatted(exceeded_size)}. You won't be able to push new code to this project. #{more_info_message}"
    end

    private

    def base_message
      "because this repository has exceeded the allocated storage for your project"
    end

    def formatted(number)
      number_to_human_size(number, delimiter: ',', precision: 2)
    end
  end
end
