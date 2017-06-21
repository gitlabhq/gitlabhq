class Geo::DeletedProject < ::Project
  after_initialize :readonly!
  attr_reader :path_with_namespace

  def initialize(id:, name:, path_with_namespace:, repository_storage: 'default')
    super(id: id, name: name, repository_storage: repository_storage)
    @path_with_namespace = path_with_namespace
  end

  def repository
    @repository ||= Repository.new(path_with_namespace, self)
  end
end
