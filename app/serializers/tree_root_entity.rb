# TODO: Inherit from TreeEntity, when `Tree` implements `id` and `name` like `Gitlab::Git::Tree`.
class TreeRootEntity < Grape::Entity
  include RequestAwareEntity

  expose :path

  expose :last_commit_path do |tree|
    logs_tree_namespace_project_ref_path(
      namespace_id: request.project.namespace.to_param, 
      project_id: request.project.to_param,
      id: request.ref,
      path: tree.path)
  end

  expose :trees, using: TreeEntity
  expose :blobs, using: BlobEntity
  expose :submodules, using: SubmoduleEntity

  expose :parent_tree_url do |tree|
    path = tree.path.sub(%r{\A/}, '')
    next unless path.present?

    path_segments = path.split('/')
    path_segments.pop
    parent_tree_path = path_segments.join('/')

    project_tree_path(request.project, File.join(request.ref, parent_tree_path))
  end
end
