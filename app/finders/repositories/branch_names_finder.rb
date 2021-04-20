# frozen_string_literal: true

module Repositories
  class BranchNamesFinder
    attr_reader :repository, :params

    def initialize(repository, params = {})
      @repository = repository
      @params = params
    end

    def execute
      return unless search

      repository.search_branch_names(search)
    end

    private

    def search
      @params[:search].presence
    end
  end
end
