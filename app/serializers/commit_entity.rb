class CommitEntity < API::Entities::RepoCommit
  include RequestAwareEntity

  expose :author, using: UserEntity

  expose :commit_path do |commit|
    namespace_project_tree_path(
      request.project.namespace,
      request.project,
      id: commit.id)
  end
end
