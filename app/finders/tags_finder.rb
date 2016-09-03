class TagsFinder
  def initialize(repository, params)
    @repository = repository
    @params = params
  end

  def execute
    tags = @repository.tags_sorted_by(sort)
    filter_by_name(tags)
  end

  private

  def sort
    @params[:sort].presence
  end

  def search
    @params[:search].presence
  end

  def filter_by_name(tags)
    if search
      tags.select { |tag| tag.name.include?(search) }
    else
      tags
    end
  end
end
