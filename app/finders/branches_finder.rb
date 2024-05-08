# frozen_string_literal: true

class BranchesFinder < GitRefsFinder
  def execute(gitaly_pagination: false)
    if gitaly_pagination && names.blank? && search.blank? && regex.blank?
      repository.branches_sorted_by(sort, pagination_params).tap do |branches|
        set_next_cursor(branches)
      end
    else
      branches = repository.branches_sorted_by(sort)
      branches = by_search(branches)
      branches = by_regex(branches)
      by_names(branches)
    end
  end

  def total
    repository.branch_count
  end

  private

  def names
    @params[:names].presence
  end

  def regex
    @params[:regex].to_s.presence
  end
  strong_memoize_attr :regex

  def page_token
    "#{Gitlab::Git::BRANCH_REF_PREFIX}#{@params[:page_token]}" if @params[:page_token]
  end

  def by_names(branches)
    return branches unless names

    branch_names = names.to_set
    branches.select do |branch|
      branch_names.include?(branch.name)
    end
  end

  def by_regex(branches)
    return branches unless regex

    branch_filter = ::Gitlab::UntrustedRegexp.new(regex)

    branches.select do |branch|
      branch_filter.match?(branch.name)
    end
  end
end
