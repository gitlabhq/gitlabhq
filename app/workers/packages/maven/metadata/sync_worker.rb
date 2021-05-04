# frozen_string_literal: true

module Packages
  module Maven
    module Metadata
      class SyncWorker
        include ApplicationWorker

        sidekiq_options retry: 3
        include Gitlab::Utils::StrongMemoize

        queue_namespace :package_repositories
        feature_category :package_registry
        tags :exclude_from_kubernetes

        deduplicate :until_executing
        idempotent!

        loggable_arguments 2

        SyncError = Class.new(StandardError)

        def perform(user_id, project_id, package_name)
          @user_id = user_id
          @project_id = project_id
          @package_name = package_name

          return unless valid?

          result = ::Packages::Maven::Metadata::SyncService.new(container: project, current_user: user, params: { package_name: @package_name })
                                                           .execute

          if result.success?
            log_extra_metadata_on_done(:message, result.message)
          else
            raise SyncError, result.message
          end

          raise SyncError, result.message unless result.success?
        end

        private

        def valid?
          @package_name.present? && user.present? && project.present?
        end

        def user
          strong_memoize(:user) do
            User.find_by_id(@user_id)
          end
        end

        def project
          strong_memoize(:project) do
            Project.find_by_id(@project_id)
          end
        end
      end
    end
  end
end
