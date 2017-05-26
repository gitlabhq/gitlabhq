class TreeEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, :path, :name, :mode

  expose :icon do |tree|
    IconsHelper.file_type_icon_class('folder', tree.mode, tree.name)
  end

  expose :url do |tree|
    namespace_project_tree_path(request.project.namespace, request.project, File.join(request.ref, tree.path))
  end
end
