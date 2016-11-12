class CommitEntity < API::Entities::RepoCommit
  include RequestAwareEntity

  expose :author, using: UserEntity

  expose :author_gravatar_url do |commit|
    GravatarService.new.execute(commit.author_email)
  end

  expose :commit_url do |commit|
    namespace_project_tree_url(
      request.project.namespace,
      request.project,
      id: commit.id)
  end
end
