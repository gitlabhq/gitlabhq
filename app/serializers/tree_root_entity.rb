# TODO: Inherit from TreeEntity, when `Tree` implements `id` and `name` like `Gitlab::Git::Tree`.
class TreeRootEntity < Grape::Entity
  expose :path
  
  expose :trees, using: TreeEntity
  expose :blobs, using: BlobEntity
  expose :submodules, using: SubmoduleEntity
end
