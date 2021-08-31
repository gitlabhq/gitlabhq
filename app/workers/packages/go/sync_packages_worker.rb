# frozen_string_literal: true

module Packages
  module Go
    class SyncPackagesWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3
      include Gitlab::Golang

      queue_namespace :package_repositories
      feature_category :package_registry

      deduplicate :until_executing
      idempotent!

      def perform(project_id, ref_name, path)
        project = Project.find_by_id(project_id)
        return unless project && project.repository.find_tag(ref_name)

        module_name = go_path(project, path)
        mod = Packages::Go::ModuleFinder.new(project, module_name).execute
        return unless mod

        ver = Packages::Go::VersionFinder.new(mod).find(ref_name)
        return unless ver

        Packages::Go::CreatePackageService.new(project, nil, version: ver).execute

      rescue ::Packages::Go::CreatePackageService::GoZipSizeError => ex
        Gitlab::ErrorTracking.log_exception(ex)
      end
    end
  end
end
