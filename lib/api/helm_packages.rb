# frozen_string_literal: true

###
# API endpoints for the Helm package registry
module API
  class HelmPackages < ::API::Base
    helpers ::API::Helpers::PackagesHelpers
    helpers ::API::Helpers::Packages::BasicAuthHelpers
    include ::API::Helpers::Authentication

    feature_category :package_registry

    FILE_NAME_REQUIREMENTS = {
      file_name: API::NO_SLASH_URL_PART_REGEX
    }.freeze

    content_type :binary, 'application/octet-stream'

    authenticate_with do |accept|
      accept.token_types(:personal_access_token, :deploy_token, :job_token)
            .sent_through(:http_basic_auth)
    end

    before do
      require_packages_enabled!
    end

    after_validation do
      not_found! unless Feature.enabled?(:helm_packages, authorized_user_project)
    end

    params do
      requires :id, type: String, desc: 'The ID or full path of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      namespace ':id/packages/helm' do
        desc 'Download a chart' do
          detail 'This feature was introduced in GitLab 14.0'
        end
        params do
          requires :channel, type: String, desc: 'Helm channel', regexp: Gitlab::Regex.helm_channel_regex
          requires :file_name, type: String, desc: 'Helm package file name'
        end
        get ":channel/charts/:file_name.tgz", requirements: FILE_NAME_REQUIREMENTS do
          authorize_read_package!(authorized_user_project)

          package_file = Packages::Helm::PackageFilesFinder.new(authorized_user_project, params[:channel], file_name: "#{params[:file_name]}.tgz").execute.last!

          track_package_event('pull_package', :helm, project: authorized_user_project, namespace: authorized_user_project.namespace)

          present_carrierwave_file!(package_file.file)
        end
      end
    end
  end
end
