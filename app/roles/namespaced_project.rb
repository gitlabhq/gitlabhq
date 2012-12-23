module NamespacedProject
  def transfer(new_namespace)
    Project.transaction do
      old_namespace = namespace
      self.namespace = new_namespace

      old_dir = old_namespace.try(:path) || ''
      new_dir = new_namespace.try(:path) || ''

      old_repo = if old_dir.present?
                   File.join(old_dir, self.path)
                 else
                   self.path
                 end

      if Project.where(path: self.path, namespace_id: new_namespace.try(:id)).present?
        raise TransferError.new("Project with same path in target namespace already exists")
      end

      Gitlab::ProjectMover.new(self, old_dir, new_dir).execute

      git_host.move_repository(old_repo, self)

      save!
    end
  rescue Gitlab::ProjectMover::ProjectMoveError => ex
    raise TransferError.new(ex.message)
  end

  def name_with_namespace
    @name_with_namespace ||= begin
                               if namespace
                                 namespace.human_name + " / " + name
                               else
                                 name
                               end
                             end
  end

  def namespace_owner
    namespace.try(:owner)
  end

  def chief
    if namespace
      namespace_owner
    else
      owner
    end
  end

  def path_with_namespace
    if namespace
      namespace.path + '/' + path
    else
      path
    end
  end
end
