module EE
  module MergeRequestWidgetEntity
    extend ActiveSupport::Concern

    prepended do
      expose :blob_path do
        expose :head_path, if: -> (mr, _) { mr.head_pipeline_sha } do |merge_request|
          project_blob_path(merge_request.project, merge_request.head_pipeline_sha)
        end

        expose :base_path, if: -> (mr, _) { mr.base_pipeline_sha } do |merge_request|
          project_blob_path(merge_request.project, merge_request.base_pipeline_sha)
        end
      end

      expose :codeclimate, if: -> (mr, _) { mr.expose_codeclimate_data? } do
        expose :head_path, if: -> (mr, _) { can?(current_user, :read_build, mr.head_codeclimate_artifact) } do |merge_request|
          raw_project_build_artifacts_url(merge_request.source_project,
                                          merge_request.head_codeclimate_artifact,
                                          path: Ci::Build::CODEQUALITY_FILE)
        end

        expose :base_path, if: -> (mr, _) { can?(current_user, :read_build, mr.base_codeclimate_artifact) } do |merge_request|
          raw_project_build_artifacts_url(merge_request.target_project,
                                          merge_request.base_codeclimate_artifact,
                                          path: Ci::Build::CODEQUALITY_FILE)
        end
      end

      expose :performance, if: -> (mr, _) { mr.expose_performance_data? } do
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

      expose :sast, if: -> (mr, _) { mr.expose_sast_data? } do
        expose :head_path, if: -> (mr, _) { can?(current_user, :read_build, mr.head_sast_artifact) } do |merge_request|
          raw_project_build_artifacts_url(merge_request.source_project,
                                          merge_request.head_sast_artifact,
                                          path: Ci::Build::SAST_FILE)
        end

        expose :base_path, if: -> (mr, _) { mr.base_has_sast_data? && can?(current_user, :read_build, mr.base_sast_artifact) } do |merge_request|
          raw_project_build_artifacts_url(merge_request.target_project,
                                          merge_request.base_sast_artifact,
                                          path: Ci::Build::SAST_FILE)
        end
      end

      expose :dependency_scanning, if: -> (mr, _) { mr.expose_dependency_scanning_data? } do
        expose :head_path, if: -> (mr, _) { can?(current_user, :read_build, mr.head_dependency_scanning_artifact) } do |merge_request|
          raw_project_build_artifacts_url(merge_request.source_project,
                                          merge_request.head_dependency_scanning_artifact,
                                          path: Ci::Build::DEPENDENCY_SCANNING_FILE)
        end

        expose :base_path, if: -> (mr, _) { mr.base_has_dependency_scanning_data? && can?(current_user, :read_build, mr.base_dependency_scanning_artifact) } do |merge_request|
          raw_project_build_artifacts_url(merge_request.target_project,
                                          merge_request.base_dependency_scanning_artifact,
                                          path: Ci::Build::DEPENDENCY_SCANNING_FILE)
        end
      end

      expose :license_management, if: -> (mr, _) { mr.expose_license_management_data? } do
        expose :head_path, if: -> (mr, _) { can?(current_user, :read_build, mr.head_license_management_artifact) } do |merge_request|
          raw_project_build_artifacts_url(merge_request.source_project,
                                          merge_request.head_license_management_artifact,
                                          path: Ci::Build::LICENSE_MANAGEMENT_FILE)
        end

        expose :base_path, if: -> (mr, _) { mr.base_has_license_management_data? && can?(current_user, :read_build, mr.base_license_management_artifact) } do |merge_request|
          raw_project_build_artifacts_url(merge_request.target_project,
                                          merge_request.base_license_management_artifact,
                                          path: Ci::Build::LICENSE_MANAGEMENT_FILE)
        end
      end

      expose :sast_container, if: -> (mr, _) { mr.expose_sast_container_data? } do
        expose :head_path, if: -> (mr, _) { can?(current_user, :read_build, mr.head_sast_container_artifact) } do |merge_request|
          raw_project_build_artifacts_url(merge_request.source_project,
                                          merge_request.head_sast_container_artifact,
                                          path: Ci::Build::SAST_CONTAINER_FILE)
        end

        expose :base_path, if: -> (mr, _) { mr.base_has_sast_container_data? && can?(current_user, :read_build, mr.base_sast_container_artifact) } do |merge_request|
          raw_project_build_artifacts_url(merge_request.target_project,
                                          merge_request.base_sast_container_artifact,
                                          path: Ci::Build::SAST_CONTAINER_FILE)
        end
      end

      expose :dast, if: -> (mr, _) { mr.expose_dast_data? } do
        expose :head_path, if: -> (mr, _) { can?(current_user, :read_build, mr.head_dast_artifact) } do |merge_request|
          raw_project_build_artifacts_url(merge_request.source_project,
                                          merge_request.head_dast_artifact,
                                          path: Ci::Build::DAST_FILE)
        end

        expose :base_path, if: -> (mr, _) { mr.base_has_dast_data? && can?(current_user, :read_build, mr.base_dast_artifact) } do |merge_request|
          raw_project_build_artifacts_url(merge_request.target_project,
                                          merge_request.base_dast_artifact,
                                          path: Ci::Build::DAST_FILE)
        end
      end

      expose :pipeline_id, if: -> (mr, _) { mr.head_pipeline } do |merge_request|
        merge_request.head_pipeline.id
      end

      expose :vulnerability_feedback_path do |merge_request|
        project_vulnerability_feedback_index_path(merge_request.project)
      end
    end
  end
end
