class CommitEntity < API::Entities::RepoCommit
  include RequestAwareEntity

  expose :author, using: UserEntity

  expose :author_gravatar_url do |commit|
    GravatarService.new.execute(commit.author_email)
  end

  expose :commit_url do |commit|
    namespace_project_commit_url(
      request.project.namespace,
      request.project,
      commit)
  end

  expose :commit_path do |commit|
    namespace_project_commit_path(
      request.project.namespace,
      request.project,
      commit)
  end
end
