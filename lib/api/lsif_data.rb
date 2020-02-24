# frozen_string_literal: true

module API
  class LsifData < Grape::API
    MAX_FILE_SIZE = 10.megabytes

    before do
      not_found! if Feature.disabled?(:code_navigation, user_project)
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
      requires :commit_id, type: String, desc: 'The ID of a commit'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      segment ':id/commits/:commit_id' do
        params do
          requires :path, type: String, desc: 'The path of a file'
        end
        get 'lsif/info' do
          authorize! :download_code, user_project

          artifact =
            Ci::JobArtifact
              .with_file_types(['lsif'])
              .for_sha(params[:commit_id], @project.id)
              .last

          not_found! unless artifact
          authorize! :read_pipeline, artifact.job.pipeline
          file_too_large! if artifact.file.cached_size > MAX_FILE_SIZE

          ::Projects::LsifDataService.new(artifact.file, @project, params).execute
        end
      end
    end
  end
end
