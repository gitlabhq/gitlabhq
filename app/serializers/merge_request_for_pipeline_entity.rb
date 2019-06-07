# frozen_string_literal: true

class MergeRequestForPipelineEntity < Grape::Entity
  include RequestAwareEntity

  expose :iid

  expose :path do |merge_request|
    project_merge_request_path(merge_request.project, merge_request)
  end

  expose :title
  expose :source_branch
  expose :source_branch_commits_path, as: :source_branch_path
  expose :target_branch
  expose :target_branch_commits_path, as: :target_branch_path
end
