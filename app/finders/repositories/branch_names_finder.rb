# frozen_string_literal: true

module Repositories
  class BranchNamesFinder
    attr_reader :repository, :params

    def initialize(repository, params = {})
      @repository = repository
      @params = params
    end

    def execute
      return unless search && offset && limit

      default_branch = repository.root_ref
      all_branch_names = repository.search_branch_names(search).sort.lazy.to_a
      deleted_branch = all_branch_names.delete(default_branch)
      all_branch_names.unshift(deleted_branch) if deleted_branch
      all_branch_names.drop(offset).take(limit) # rubocop:disable CodeReuse/ActiveRecord -- Results returned from redis not database
    end

    private

    def search
      @params[:search].presence
    end

    def offset
      @params[:offset]
    end

    def limit
      @params[:limit]
    end
  end
end
