# frozen_string_literal: true

class GitRefsFinder
  def initialize(repository, params = {})
    @repository = repository
    @params = params
  end

  protected

  attr_reader :repository, :params

  def search
    @params[:search].presence
  end

  def sort
    @params[:sort].presence || 'name'
  end

  def by_search(refs)
    return refs unless search

    case search
    when ->(v) { v.starts_with?('^') }
      filter_refs_with_prefix(refs, search.slice(1..-1))
    when ->(v) { v.ends_with?('$') }
      filter_refs_with_suffix(refs, search.chop)
    else
      matches = filter_refs_by_name(refs, search)
      set_exact_match_as_first_result(matches, search)
    end
  end

  def filter_refs_with_prefix(refs, prefix)
    prefix = prefix.downcase

    refs.select { |ref| ref.name.downcase.starts_with?(prefix) }
  end

  def filter_refs_with_suffix(refs, suffix)
    suffix = suffix.downcase

    refs.select { |ref| ref.name.downcase.ends_with?(suffix) }
  end

  def filter_refs_by_name(refs, term)
    term = term.downcase

    refs.select { |ref| ref.name.downcase.include?(term) }
  end

  def set_exact_match_as_first_result(matches, term)
    exact_match_index = find_exact_match_index(matches, term)
    matches.insert(0, matches.delete_at(exact_match_index)) if exact_match_index
    matches
  end

  def find_exact_match_index(matches, term)
    matches.index { |ref| ref.name.casecmp(term) == 0 }
  end
end
