# frozen_string_literal: true

class GitRefsFinder
  include Gitlab::Utils::StrongMemoize

  attr_reader :next_cursor

  def initialize(repository, params = {})
    @repository = repository
    @params = params
    @next_cursor = nil
  end

  protected

  attr_reader :repository, :params

  def by_search(refs)
    return refs unless search

    matches = filter_refs(refs, search)
    return matches if regex_search?

    set_exact_match_as_first_result(matches, search)
  end

  def search
    @params[:search].to_s.presence
  end
  strong_memoize_attr :search

  def sort
    @params[:sort].to_s.presence || 'name'
  end

  def pagination_params
    { limit: per_page, page_token: page_token }
  end

  def per_page
    return if params[:per_page].blank?

    Gitlab::PaginationDelegate.new(
      per_page: params[:per_page].presence, page: nil, count: nil
    ).limit_value
  end

  def filter_refs(refs, term)
    regex_string = RE2::Regexp.escape(term.downcase)
    regex_string = unescape_regex_operators(regex_string) if regex_search?
    regex_string = Gitlab::UntrustedRegexp.new(regex_string)

    refs.select { |ref| regex_string.match?(ref.name.downcase) }
  end

  def set_exact_match_as_first_result(matches, term)
    exact_match_index = find_exact_match_index(matches, term)
    matches.insert(0, matches.delete_at(exact_match_index)) if exact_match_index
    matches
  end

  def find_exact_match_index(matches, term)
    matches.index { |ref| ref.name.casecmp(term) == 0 }
  end

  def regex_search?
    Regexp.union('^', '$', '*') === search
  end
  strong_memoize_attr :regex_search?

  def unescape_regex_operators(regex_string)
    regex_string.sub('\^', '^').gsub('\*', '.*?').sub('\$', '$')
  end

  def set_next_cursor(records)
    return if records.blank?

    # TODO: Gitaly should be responsible for a cursor generation
    # Follow-up for branches: https://gitlab.com/gitlab-org/gitlab/-/issues/431903
    # Follow-up for tags: https://gitlab.com/gitlab-org/gitlab/-/issues/431904
    @next_cursor = records.last.name
  end
end
