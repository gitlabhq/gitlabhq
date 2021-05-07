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

      repository.search_branch_names(search).lazy.drop(offset).take(limit) # rubocop:disable CodeReuse/ActiveRecord
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
