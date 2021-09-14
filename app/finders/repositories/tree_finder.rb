# frozen_string_literal: true

module Repositories
  class TreeFinder < GitRefsFinder
    attr_reader :user_project

    CommitMissingError = Class.new(StandardError)

    def initialize(user_project, params = {})
      super(user_project.repository, params)

      @user_project = user_project
    end

    def execute(gitaly_pagination: false)
      raise CommitMissingError unless commit_exists?

      request_params = { recursive: recursive }
      request_params[:pagination_params] = pagination_params if gitaly_pagination
      tree = user_project.repository.tree(commit.id, path, **request_params)

      tree.sorted_entries
    end

    def total
      # This is inefficient and we'll look at replacing this implementation
      Gitlab::Cache.fetch_once([user_project, repository.commit, :tree_size, commit.id, path, recursive]) do
        user_project.repository.tree(commit.id, path, recursive: recursive).entries.size
      end
    end

    def commit_exists?
      commit.present?
    end

    private

    def commit
      @commit ||= user_project.commit(ref)
    end

    def ref
      params[:ref] || user_project.default_branch
    end

    def path
      params[:path]
    end

    def recursive
      params[:recursive]
    end

    def pagination_params
      {
        limit: params[:per_page] || Kaminari.config.default_per_page,
        page_token: params[:page_token]
      }
    end
  end
end
