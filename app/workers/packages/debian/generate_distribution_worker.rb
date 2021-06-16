# frozen_string_literal: true

module Packages
  module Debian
    class GenerateDistributionWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker
      include Gitlab::Utils::StrongMemoize

      # The worker is idempotent, by reusing component files with the same file_sha256.
      #
      # See GenerateDistributionService#find_or_create_component_file
      deduplicate :until_executed
      idempotent!

      queue_namespace :package_repositories
      feature_category :package_registry

      loggable_arguments 0

      def perform(container_type, distribution_id)
        @container_type = container_type
        @distribution_id = distribution_id

        return unless distribution

        ::Packages::Debian::GenerateDistributionService.new(distribution).execute
      end

      private

      def container_class
        return ::Packages::Debian::GroupDistribution if @container_type == :group

        ::Packages::Debian::ProjectDistribution
      end

      def distribution
        strong_memoize(:distribution) do
          container_class.find_by_id(@distribution_id)
        end
      end
    end
  end
end
