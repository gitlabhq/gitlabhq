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

      expose_artifact(:sast, Ci::Build::SAST_FILE)
      expose_artifact(:sast_container, Ci::Build::SAST_CONTAINER_FILE)
      expose_artifact(:dast, Ci::Build::DAST_FILE)
    end

    class_methods do
      def expose_artifact(name, file)
        expose name, if: -> (mr, _) { mr.send(:"expose_#{name}_data?") } do
          base_artifact_method = :"base_#{name}_artifact"
          head_artifact_method = :"head_#{name}_artifact"

          expose :head_path, if: -> (mr, _) { can?(current_user, :read_build, mr.send(head_artifact_method)) } do |merge_request|
            raw_project_build_artifacts_url(merge_request.source_project,
                                            merge_request.send(head_artifact_method),
                                            path: file)
          end

          expose :base_path, if: -> (mr, _) { mr.send(:"base_has_#{name}_data?") && can?(current_user, :read_build, mr.send(base_artifact_method)) } do |merge_request|
            raw_project_build_artifacts_url(merge_request.target_project,
                                            merge_request.send(base_artifact_method),
                                            path: file)
          end
        end
      end
    end
  end
end
