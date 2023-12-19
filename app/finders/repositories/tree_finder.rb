# frozen_string_literal: true

module Repositories
  class TreeFinder
    CommitMissingError = Class.new(StandardError)

    attr_reader :next_cursor

    def initialize(project, params = {})
      @project = project
      @repository = project.repository
      @params = params
      @next_cursor = nil
    end

    def execute(gitaly_pagination: false)
      raise CommitMissingError unless commit_exists?

      request_params = { recursive: recursive, rescue_not_found: rescue_not_found }
      request_params[:pagination_params] = pagination_params if gitaly_pagination

      tree = repository.tree(commit.id, path, **request_params)

      @next_cursor = tree.cursor&.next_cursor if gitaly_pagination

      tree.sorted_entries
    end

    def total
      # This is inefficient and we'll look at replacing this implementation
      cache_key = [project, repository.commit, :tree_size, commit.id, path, recursive]
      Gitlab::Cache.fetch_once(cache_key) do
        repository.tree(commit.id, path, recursive: recursive).entries.size
      end
    end

    def commit_exists?
      commit.present?
    end

    private

    attr_reader :project, :repository, :params

    def commit
      @commit ||= project.commit(ref)
    end

    def ref
      params[:ref] || project.default_branch
    end

    def path
      params[:path]
    end

    def recursive
      params[:recursive]
    end

    def rescue_not_found
      params[:rescue_not_found]
    end

    def pagination_params
      {
        limit: params[:per_page] || Kaminari.config.default_per_page,
        page_token: params[:page_token]
      }
    end
  end
end
