# frozen_string_literal: true
module API
  class RpmProjectPackages < ::API::Base
    helpers ::API::Helpers::PackagesHelpers
    feature_category :package_registry

    before do
      require_packages_enabled!
      not_found! unless Feature.enabled?(:rpm_packages)
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      namespace ':id/packages/rpm' do
        desc 'Download repository metadata files'
        params do
          requires :file_name, type: String, desc: 'Repository metadata file name'
        end
        get 'repodata/*file_name' do
          not_found!
        end

        desc 'Download RPM package files'
        params do
          requires :package_file_id, type: Integer, desc: 'RPM package file id'
          requires :file_name, type: String, desc: 'RPM package file name'
        end
        get '*package_file_id/*file_name' do
          not_found!
        end

        desc 'Upload a RPM package'
        post do
          not_found!
        end

        desc 'Authorize package upload from workhorse'
        post 'authorize' do
          not_found!
        end
      end
    end
  end
end
