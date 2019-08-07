# frozen_string_literal: true

class BranchesFinder
  def initialize(repository, params = {})
    @repository = repository
    @params = params
  end

  def execute
    branches = repository.branches_sorted_by(sort)
    branches = by_search(branches)
    branches = by_names(branches)
    branches
  end

  private

  attr_reader :repository, :params

  def names
    @params[:names].presence
  end

  def search
    @params[:search].presence
  end

  def sort
    @params[:sort].presence || 'name'
  end

  def by_search(branches)
    return branches unless search

    case search
    when ->(v) { v.starts_with?('^') }
      filter_branches_with_prefix(branches, search.slice(1..-1).upcase)
    when ->(v) { v.ends_with?('$') }
      filter_branches_with_suffix(branches, search.chop.upcase)
    else
      matches = filter_branches_by_name(branches, search.upcase)
      set_exact_match_as_first_result(matches, search)
    end
  end

  def filter_branches_with_prefix(branches, prefix)
    branches.select { |branch| branch.name.upcase.starts_with?(prefix) }
  end

  def filter_branches_with_suffix(branches, suffix)
    branches.select { |branch| branch.name.upcase.ends_with?(suffix) }
  end

  def filter_branches_by_name(branches, term)
    branches.select { |branch| branch.name.upcase.include?(term) }
  end

  def set_exact_match_as_first_result(matches, term)
    exact_match_index = find_exact_match_index(matches, term)
    matches.insert(0, matches.delete_at(exact_match_index)) if exact_match_index
    matches
  end

  def find_exact_match_index(matches, term)
    matches.index { |branch| branch.name.casecmp(term) == 0 }
  end

  def by_names(branches)
    return branches unless names

    branch_names = names.to_set
    branches.select do |branch|
      branch_names.include?(branch.name)
    end
  end
end
