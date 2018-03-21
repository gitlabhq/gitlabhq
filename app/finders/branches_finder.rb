class BranchesFinder
  def initialize(repository, params = {})
    @repository = repository
    @params = params
  end

  def execute
    branches = @repository.branches_sorted_by(sort)
    filter_by_name(branches)
  end

  private

  attr_reader :repository, :params

  def search
    @params[:search].presence
  end

  def sort
    @params[:sort].presence || 'name'
  end

  def filter_by_name(branches)
    if search
      branches.select { |branch| branch.name.upcase.include?(search.upcase) }
    else
      branches
    end
  end
end
