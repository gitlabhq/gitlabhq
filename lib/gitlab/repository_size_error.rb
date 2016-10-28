module Gitlab
  class RepositorySizeError
    include ActiveSupport::NumberHelper

    attr_reader :project

    def initialize(project)
      @project = project
    end

    def to_s
      "The size of this repository (#{current_size}) exceeds the limit of #{limit} by #{size_to_remove}."
    end

    def commit_error
      "Your changes could not be committed, #{base_message}"
    end

    def merge_error
      "This merge request cannot be merged, #{base_message}"
    end

    def push_error
      "Your push has been rejected, #{base_message}. #{more_info_message}"
    end

    def new_changes_error
      "Your push to this repository would cause it to exceed the size limit of #{limit} so it has been rejected. #{more_info_message}"
    end

    def more_info_message
      'Please contact your GitLab administrator for more information.'
    end

    def above_size_limit_message
      "#{self} You won't be able to push new code to this project. #{more_info_message}"
    end

    private

    def base_message
      "because this repository has exceeded its size limit of #{limit} by #{size_to_remove}"
    end

    def current_size
      format_number(project.repository_and_lfs_size)
    end

    def limit
      format_number(project.actual_size_limit)
    end

    def size_to_remove
      format_number(project.size_to_remove)
    end

    def format_number(number)
      number_to_human_size(number * 1.megabyte, delimiter: ',', precision: 2)
    end
  end
end
