class CommitEntity < API::Entities::Commit
  include RequestAwareEntity

  expose :author, using: UserEntity

  expose :author_gravatar_url do |commit|
    GravatarService.new.execute(commit.author_email)
  end

  expose :commit_url do |commit|
    project_commit_url(request.project, commit)
  end

  expose :commit_path do |commit|
    project_commit_path(request.project, commit)
  end
end
