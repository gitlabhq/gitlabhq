# ProjectTransferService class
#
# Used for transfer project to another namespace
#
class ProjectTransferService
  attr_accessor :project

  def transfer(project, new_namespace)
    Project.transaction do
      old_namespace = project.namespace
      project.namespace = new_namespace

      old_dir = old_namespace.try(:path) || ''
      new_dir = new_namespace.try(:path) || ''

      old_repo = if old_dir.present?
                   File.join(old_dir, project.path)
                 else
                   project.path
                 end

      if Project.where(path: project.path, namespace_id: new_namespace.try(:id)).present?
        raise TransferError.new("Project with same path in target namespace already exists")
      end

      Gitlab::ProjectMover.new(project, old_dir, new_dir).execute

      project.save!
    end
  rescue Gitlab::ProjectMover::ProjectMoveError => ex
    raise Project::TransferError.new(ex.message)
  end
end

