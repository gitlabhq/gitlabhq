class Geo::DeletedProject < ::Project
  after_initialize :readonly!

  def initialize(id:, name:, full_path:, repository_storage:)
    repository_storage ||= current_application_settings.pick_repository_storage

    super(id: id, name: name, repository_storage: repository_storage)
    @full_path = full_path
  end

  def full_path
    @full_path
  end
  alias_method :path_with_namespace, :full_path
end
