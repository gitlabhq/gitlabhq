class TreeEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, :path, :name, :mode

  expose :last_commit do |tree|
    request.project.repository.last_commit_for_path(tree.commit_id, tree.path)
  end

  expose :icon do |tree|
    IconsHelper.file_type_icon_class('folder', tree.mode, tree.name)
  end

  expose :url do |tree|
    project_tree_path(request.project, File.join(request.ref, tree.path))
  end
end
