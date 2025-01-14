# frozen_string_literal: true

module Packages
  module Npm
    class DeprecatePackageService < BaseService
      include Gitlab::Utils::StrongMemoize

      BATCH_SIZE = 50

      def initialize(project, params)
        super(project, nil, params)
      end

      def execute
        enqueue_metadata_cache_worker = false

        packages.select(:id, :version, :package_type).each_batch(of: BATCH_SIZE) do |relation|
          attributes = relation.preload_npm_metadatum.filter_map { |package| metadatum_attributes(package) }
          next if attributes.empty?

          package_ids = attributes.pluck(:package_id) # rubocop:disable CodeReuse/ActiveRecord, Database/AvoidUsingPluckWithoutLimit -- This is a hash, not an ActiveRecord relation.

          ApplicationRecord.transaction do
            ::Packages::Npm::Metadatum.upsert_all(attributes)
            ::Packages::Package.id_in(package_ids).update_all(status: package_status)
          end

          enqueue_metadata_cache_worker = true
        end

        if enqueue_metadata_cache_worker
          ::Packages::Npm::CreateMetadataCacheWorker.perform_async(project.id, params['package_name'])
        end

        ServiceResponse.success
      end

      private

      def packages
        ::Packages::Npm::PackageFinder.new(
          project: project,
          params: {
            package_name: params['package_name'],
            package_version: params['versions'].keys
          }
        ).execute
      end

      def metadatum_attributes(package)
        package_json = params.dig('versions', package.version)

        npm_metadatum = package.npm_metadatum || package.build_npm_metadatum(package_json: package_json)
        return if npm_metadatum.persisted? && identical?(npm_metadatum.package_json['deprecated'])

        if npm_metadatum.valid?
          { package_id: package.id, package_json: update_package_json(npm_metadatum.package_json) }
        else
          Gitlab::ErrorTracking.track_exception(
            ActiveRecord::RecordInvalid.new(npm_metadatum),
            class: self.class.name,
            package_id: package.id
          )

          nil
        end
      end

      def identical?(package_json_deprecated)
        package_json_deprecated == deprecation_message ||
          (package_json_deprecated.nil? && deprecation_message_empty?)
      end

      def update_package_json(package_json)
        if deprecation_message_empty?
          package_json.delete('deprecated')
        else
          package_json['deprecated'] = deprecation_message
        end

        package_json
      end

      def deprecation_message_empty?
        deprecation_message.empty?
      end
      strong_memoize_attr :deprecation_message_empty?

      def deprecation_message
        _, metadatum = params['versions'].first
        metadatum['deprecated']
      end
      strong_memoize_attr :deprecation_message

      def package_status
        return ::Packages::Package.statuses[:default] if deprecation_message_empty?

        ::Packages::Package.statuses[:deprecated]
      end
      strong_memoize_attr :package_status
    end
  end
end
