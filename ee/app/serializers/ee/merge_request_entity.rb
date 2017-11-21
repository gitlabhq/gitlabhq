module EE
  module MergeRequestEntity
    extend ActiveSupport::Concern

    prepended do
      expose :codeclimate, if: -> (mr, _) { mr.has_codeclimate_data? } do
        expose :head_path, if: -> (mr, _) { can?(current_user, :read_build, mr.head_codeclimate_artifact) } do |merge_request|
          raw_project_build_artifacts_url(merge_request.source_project,
                                          merge_request.head_codeclimate_artifact,
                                          path: 'codeclimate.json')
        end

        expose :head_blob_path, if: -> (mr, _) { mr.head_pipeline_sha } do |merge_request|
          project_blob_path(merge_request.project, merge_request.head_pipeline_sha)
        end

        expose :base_path, if: -> (mr, _) { can?(current_user, :read_build, mr.base_codeclimate_artifact) } do |merge_request|
          raw_project_build_artifacts_url(merge_request.target_project,
                                          merge_request.base_codeclimate_artifact,
                                          path: 'codeclimate.json')
        end

        expose :base_blob_path, if: -> (mr, _) { mr.base_pipeline_sha } do |merge_request|
          project_blob_path(merge_request.project, merge_request.base_pipeline_sha)
        end
      end

      expose :sast, if: -> (mr, _) { expose_sast_data?(mr, current_user) } do
        expose :path do |merge_request|
          raw_project_build_artifacts_url(merge_request.source_project,
                                          merge_request.sast_artifact,
                                          path: 'gl-sast-report.json')
        end

        expose :blob_path, if: -> (mr, _) { mr.head_pipeline_sha } do |merge_request|
          project_blob_path(merge_request.project, merge_request.head_pipeline_sha)
        end
      end
    end

    private

    def expose_sast_data?(mr, current_user)
      mr.project.feature_available?(:sast) &&
        mr.has_sast_data? &&
        can?(current_user, :read_build, mr.sast_artifact)
    end
  end
end
