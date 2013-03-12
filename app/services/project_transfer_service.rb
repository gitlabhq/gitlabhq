# ProjectTransferService class
#
# Used for transfer project to another namespace
#
class ProjectTransferService
  include Gitolited

  attr_accessor :project

  def transfer(project, new_namespace)
    Project.transaction do
      old_path = project.path_with_namespace
      new_path = File.join(new_namespace.try(:path) || '', project.path)

      if Project.where(path: project.path, namespace_id: new_namespace.try(:id)).present?
        raise TransferError.new("Project with same path in target namespace already exists")
      end

      project.namespace = new_namespace
      project.save!

      unless gitlab_shell.mv_repository(old_path, new_path)
        raise TransferError.new('Cannot move project')
      end

      true
    end
  rescue => ex
    raise Project::TransferError.new(ex.message)
  end
end

