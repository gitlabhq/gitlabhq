# frozen_string_literal: true

class MergeRequestCurrentUserEntity < CurrentUserEntity
  include RequestAwareEntity
  include BlobHelper
  include TreeHelper

  expose :can_fork do |user|
    project && can?(user, :fork_project, request.project)
  end

  expose :can_create_merge_request do |user|
    project && can?(user, :create_merge_request_in, project)
  end

  expose :fork_path, if: ->(*) { project } do |user|
    params = edit_blob_fork_params("Edit")
    project_forks_path(project, namespace_key: user.namespace.id, continue: params)
  end

  def project
    request.respond_to?(:project) && request.project
  end
end
