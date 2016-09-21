class BranchesFinder
  def initialize(repository, params)
    @repository = repository
    @params = params
  end

  def execute
    branches = @repository.branches_sorted_by(sort2)
    filter_by_name(branches)
  end

  private

  attr_reader :repository, :params

  def search
    @params[:search].presence
  end

  def sort2
    @params[:sort].presence || 'name'
  end

  def filter_by_name(branches)
    if search
      branches.select { |branch| branch.name.include?(search) }
    else
      branches
    end
  end
end
