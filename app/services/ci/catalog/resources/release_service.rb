# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      class ReleaseService
        def initialize(release, user)
          @release = release
          @user = user
          @project = release.project
          @errors = []
        end

        def execute
          track_release_duration do
            validate_catalog_resource
            create_version
          end

          if errors.empty?
            ServiceResponse.success
          else
            ServiceResponse.error(message: errors.join(', '))
          end
        end

        private

        attr_reader :project, :errors, :release, :user

        def track_release_duration
          name = :gitlab_ci_catalog_release_duration_seconds
          comment = 'CI Catalog Release duration'
          buckets = [0.01, 0.05, 0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 240.0]

          histogram = ::Gitlab::Metrics.histogram(name, comment, {}, buckets)
          start_time = ::Gitlab::Metrics::System.monotonic_time

          yield

          duration = ::Gitlab::Metrics::System.monotonic_time - start_time
          histogram.observe({}, duration.seconds)
        end

        def validate_catalog_resource
          response = Ci::Catalog::Resources::ValidateService.new(project, release.sha).execute
          return if response.success?

          errors << response.message
        end

        def create_version
          return if errors.present?

          response = Ci::Catalog::Resources::Versions::CreateService.new(release, user).execute
          return if response.success?

          errors << response.message
        end
      end
    end
  end
end
