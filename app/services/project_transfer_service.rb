# ProjectTransferService class
#
# Used for transfer project to another namespace
#
class ProjectTransferService
  include Gitlab::ShellAdapter

  class TransferError < StandardError; end

  attr_accessor :project

  def transfer(project, new_namespace)
    Project.transaction do
      old_path = project.path_with_namespace
      new_path = File.join(new_namespace.try(:path) || '', project.path)

      if Project.where(path: project.path, namespace_id: new_namespace.try(:id)).present?
        raise TransferError.new("Project with same path in target namespace already exists")
      end

      # Remove old satellite
      project.satellite.destroy

      # Apply new namespace id
      project.namespace = new_namespace
      project.save!

      # Move main repository
      unless gitlab_shell.mv_repository(old_path, new_path)
        raise TransferError.new('Cannot move project')
      end

      # Move wiki repo also if present
      gitlab_shell.mv_repository("#{old_path}.wiki", "#{new_path}.wiki")

      # Create a new satellite (reload project from DB)
      Project.find(project.id).ensure_satellite_exists

      # clear project cached events
      project.reset_events_cache

      true
    end
  end
end

