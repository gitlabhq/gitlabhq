# frozen_string_literal: true

module Snippets
  class RepositoryValidationService
    attr_reader :current_user, :snippet, :repository

    RepositoryValidationError = Class.new(StandardError)

    def initialize(user, snippet)
      @current_user = user
      @snippet = snippet
      @repository = snippet.repository
    end

    def execute
      if snippet.nil?
        return service_response_error('No snippet found.', 404)
      end

      check_branch_count!
      check_branch_name_default!
      check_tag_count!
      check_file_count!
      check_size!

      ServiceResponse.success(message: 'Valid snippet repository.')
    rescue RepositoryValidationError => e
      ServiceResponse.error(message: "Error: #{e.message}", http_status: 400)
    end

    private

    def check_branch_count!
      return if repository.branch_count == 1

      raise RepositoryValidationError, _('Repository has more than one branch.')
    end

    def check_branch_name_default!
      branches = repository.branch_names

      return if branches.first == snippet.default_branch

      raise RepositoryValidationError, _('Repository has an invalid default branch name.')
    end

    def check_tag_count!
      return if repository.tag_count == 0

      raise RepositoryValidationError, _('Repository has tags.')
    end

    def check_file_count!
      file_count = repository.ls_files(snippet.default_branch).size
      limit = Snippet.max_file_limit

      if file_count > limit
        raise RepositoryValidationError, _('Repository files count over the limit')
      end

      if file_count == 0
        raise RepositoryValidationError, _('Repository must contain at least 1 file.')
      end
    end

    def check_size!
      return unless snippet.repository_size_checker.above_size_limit?

      raise RepositoryValidationError, _('Repository size is above the limit.')
    end
  end
end
