class CommitEntity < API::Entities::RepoCommit
  include RequestAwareEntity

  expose :author, using: API::Entities::UserBasic

  expose :commit_url do |commit|
    @urls.namespace_project_tree_url(
      @request.project.namespace,
      @request.project,
      id: commit.id)
  end
end
