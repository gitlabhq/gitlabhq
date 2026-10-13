# frozen_string_literal: true

module Tasks
  module Ci
    class BackfillCatalogBundlesTask
      def initialize
        @succeeded = 0
        @rejected = 0
        @errored = 0
      end

      def execute
        versions_to_collect.find_each { |version| collect(version) }

        puts "#{@succeeded} succeeded, #{@rejected} rejected, #{@errored} errored"
        abort 'Collection raised for some versions. Rerun the task to retry them.' if @errored > 0
      end

      private

      def versions_to_collect
        ::Ci::Catalog::Resources::Version
          .with_semver
          .joins(:catalog_resource)
          .merge(::Ci::Catalog::Resource.published.for_verification_level(:gitlab_maintained))
          .preloaded
      end

      def collect(version)
        response = ::Ci::Catalog::BundledResources::CollectAndStoreService.new(version).execute

        if response.success?
          @succeeded += 1
        else
          @rejected += 1
          report_failure(version, response.reason, response.message)
        end
      rescue StandardError => e
        @errored += 1
        report_failure(version, e.class.name, e.message)
      end

      def report_failure(version, reason, message)
        puts "#{version.project.full_path}@#{version.semver}: #{reason}: #{message}"
      end
    end
  end
end
