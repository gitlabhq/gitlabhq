# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      class ReleaseService
        def initialize(release, user, metadata)
          @release = release
          @user = user
          @metadata = metadata
          @project = release.project
          @errors = []
        end

        def execute
          resource_version = track_release_duration do
            check_access
            validate_catalog_resource
            create_version
          end

          if errors.empty?
            ServiceResponse.success(payload: { version: resource_version })
          else
            ServiceResponse.error(message: errors.join(', '))
          end
        end

        private

        attr_reader :project, :errors, :release, :user, :metadata

        def track_release_duration
          name = :gitlab_ci_catalog_release_duration_seconds
          comment = 'CI Catalog Release duration'
          buckets = [0.01, 0.05, 0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 240.0]

          histogram = ::Gitlab::Metrics.histogram(name, comment, {}, buckets)
          start_time = ::Gitlab::Metrics::System.monotonic_time

          result = yield

          duration = ::Gitlab::Metrics::System.monotonic_time - start_time
          histogram.observe({}, duration.seconds)

          result
        end

        def check_access
          return if Ability.allowed?(user, :publish_catalog_version, release)

          errors << 'You are not authorized to publish a version to the CI/CD catalog'
        end

        def validate_catalog_resource
          return if errors.present?

          response = Ci::Catalog::Resources::ValidateService.new(project, release.sha).execute
          return if response.success?

          errors << response.message
        end

        def create_version
          return if errors.present?

          response = Ci::Catalog::Resources::Versions::CreateService.new(release, user, metadata).execute
          return response.payload[:version] if response.success?

          errors << response.message

          nil
        end
      end
    end
  end
end
