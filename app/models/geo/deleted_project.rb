class Geo::DeletedProject < ::Project
  after_initialize :readonly!
  attr_reader :full_path

  def initialize(id:, name:, full_path:, repository_storage:)
    repository_storage ||= current_application_settings.pick_repository_storage

    super(id: id, name: name, repository_storage: repository_storage)
    @full_path = full_path
  end

  def repository
    @repository ||= Repository.new(full_path, self)
  end
end
