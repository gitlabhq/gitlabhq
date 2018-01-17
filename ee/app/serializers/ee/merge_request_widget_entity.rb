module EE
  module MergeRequestWidgetEntity
    extend ActiveSupport::Concern

    prepended do
      expose :codeclimate, if: -> (mr, _) { mr.has_codeclimate_data? } do
        expose :head_path, if: -> (mr, _) { can?(current_user, :read_build, mr.head_codeclimate_artifact) } do |merge_request|
          raw_project_build_artifacts_url(merge_request.source_project,
                                          merge_request.head_codeclimate_artifact,
                                          path: Ci::Build::CODEQUALITY_FILE)
        end

        expose :head_blob_path, if: -> (mr, _) { mr.head_pipeline_sha } do |merge_request|
          project_blob_path(merge_request.project, merge_request.head_pipeline_sha)
        end

        expose :base_path, if: -> (mr, _) { can?(current_user, :read_build, mr.base_codeclimate_artifact) } do |merge_request|
          raw_project_build_artifacts_url(merge_request.target_project,
                                          merge_request.base_codeclimate_artifact,
                                          path: Ci::Build::CODEQUALITY_FILE)
        end

        expose :base_blob_path, if: -> (mr, _) { mr.base_pipeline_sha } do |merge_request|
          project_blob_path(merge_request.project, merge_request.base_pipeline_sha)
        end
      end

      expose :performance, if: -> (mr, _) { expose_performance_data?(mr) } do
        expose :head_path, if: -> (mr, _) { can?(current_user, :read_build, mr.head_performance_artifact) } do |merge_request|
          raw_project_build_artifacts_url(merge_request.source_project,
                                          merge_request.head_performance_artifact,
                                          path: Ci::Build::PERFORMANCE_FILE)
        end

        expose :base_path, if: -> (mr, _) { can?(current_user, :read_build, mr.base_performance_artifact) } do |merge_request|
          raw_project_build_artifacts_url(merge_request.target_project,
                                          merge_request.base_performance_artifact,
                                          path: Ci::Build::PERFORMANCE_FILE)
        end
      end

      expose :sast, if: -> (mr, _) { expose_sast_data?(mr, current_user) } do
        expose :path do |merge_request|
          raw_project_build_artifacts_url(merge_request.source_project,
                                          merge_request.sast_artifact,
                                          path: Ci::Build::SAST_FILE)
        end

        expose :blob_path, if: -> (mr, _) { mr.head_pipeline_sha } do |merge_request|
          project_blob_path(merge_request.project, merge_request.head_pipeline_sha)
        end
      end

      expose :sast_container, if: -> (mr, _) { expose_sast_container_data?(mr, current_user) } do
        expose :path do |merge_request|
          raw_project_build_artifacts_url(merge_request.source_project,
                                          merge_request.sast_container_artifact,
                                          path: Ci::Build::SAST_CONTAINER_FILE)
        end

        expose :blob_path, if: -> (mr, _) { mr.head_pipeline_sha } do |merge_request|
          project_blob_path(merge_request.project, merge_request.head_pipeline_sha)
        end
      end

      expose :dast, if: -> (mr, _) { expose_dast_data?(mr, current_user) } do
        expose :path do |merge_request|
          raw_project_build_artifacts_url(merge_request.source_project,
                                          merge_request.dast_artifact,
                                          path: Ci::Build::DAST_FILE)
        end
      end
    end

    private

    def expose_sast_data?(mr, current_user)
      mr.project.feature_available?(:sast) &&
        mr.has_sast_data? &&
        can?(current_user, :read_build, mr.sast_artifact)
    end

    def expose_performance_data?(mr)
      mr.project.feature_available?(:merge_request_performance_metrics) &&
        mr.has_performance_data?
    end

    def expose_sast_container_data?(mr, current_user)
      mr.project.feature_available?(:sast_container) &&
        mr.has_sast_container_data? &&
        can?(current_user, :read_build, mr.sast_container_artifact)
    end

    def expose_dast_data?(mr, current_user)
      mr.project.feature_available?(:dast) &&
        mr.has_dast_data? &&
        can?(current_user, :read_build, mr.dast_artifact)
    end
  end
end
