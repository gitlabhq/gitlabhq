# TODO: Inherit from TreeEntity, when `Tree` implements `id` and `name` like `Gitlab::Git::Tree`.
class TreeRootEntity < Grape::Entity
  include RequestAwareEntity

  expose :last_commit, using: CommitEntity do |tree|
    request.project.repository.last_commit_for_path(request.commit.id, tree.path) || request.commit
  end

  expose :path

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
