# frozen_string_literal: true

module API
  class ProjectAvatar < ::API::Base
    feature_category :groups_and_projects

    params do
      requires :id, types: [String, Integer], desc: 'ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Download a project avatar' do
        detail 'This feature was introduced in GitLab 16.9'
        tags %w[project_avatar]
        success code: 200
      end
      get ':id/avatar' do
        avatar = user_project.avatar

        not_found!('Avatar') if avatar.blank?

        header(
          'Content-Disposition',
          ActionDispatch::Http::ContentDisposition.format(
            disposition: 'attachment',
            filename: avatar.filename
          )
        )

        present_carrierwave_file!(avatar)
      end
    end
  end
end
