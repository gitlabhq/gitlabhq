# frozen_string_literal: true

class BranchesFinder < GitRefsFinder
  def initialize(repository, params = {})
    super(repository, params)
  end

  def execute
    branches = repository.branches_sorted_by(sort)
    branches = by_search(branches)
    branches = by_names(branches)
    branches
  end

  private

  def names
    @params[:names].presence
  end

  def by_names(branches)
    return branches unless names

    branch_names = names.to_set
    branches.select do |branch|
      branch_names.include?(branch.name)
    end
  end
end
