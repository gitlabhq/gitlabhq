module FilterBranches
  extend ActiveSupport::Concern

  def filter_branches(branches)
    if params[:search].present? && @sort
      branches = @repository.find_similar_branches(params[:search], @sort)
  end
end
