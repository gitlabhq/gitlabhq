# frozen_string_literal: true

class BranchesFinder < GitRefsFinder
  def initialize(repository, params = {})
    super(repository, params)
  end

  def execute(gitaly_pagination: false)
    if gitaly_pagination && names.blank? && search.blank?
      repository.branches_sorted_by(sort, pagination_params)
    else
      branches = repository.branches_sorted_by(sort)
      branches = by_search(branches)
      by_names(branches)
    end
  end

  private

  def names
    @params[:names].presence
  end

  def per_page
    @params[:per_page].presence
  end

  def page_token
    "#{Gitlab::Git::BRANCH_REF_PREFIX}#{@params[:page_token]}" if @params[:page_token]
  end

  def pagination_params
    { limit: per_page, page_token: page_token }
  end

  def by_names(branches)
    return branches unless names

    branch_names = names.to_set
    branches.select do |branch|
      branch_names.include?(branch.name)
    end
  end
end
