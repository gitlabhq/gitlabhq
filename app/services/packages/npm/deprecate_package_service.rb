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
          attributes_with_status = relation.preload_npm_metadatum.filter_map { |package| metadatum_attributes(package) }
          next if attributes_with_status.empty?

          # Group packages by status since different packages may have different statuses
          grouped_by_status = attributes_with_status.group_by { |attr| attr[:status] }

          ApplicationRecord.transaction do
            # Upsert all metadatum records
            metadatum_attributes = attributes_with_status.map { |attr| attr.slice(:package_id, :package_json) }
            ::Packages::Npm::Metadatum.upsert_all(metadatum_attributes)

            # Update package status separately for each status group
            grouped_by_status.each do |status, attrs|
              package_ids = attrs.map { |attr| attr[:package_id] } # rubocop:disable Rails/Pluck -- attrs is a plain array, not AR relation
              ::Packages::Package.id_in(package_ids).update_all(status: status)
            end
          end

          enqueue_metadata_cache_worker = true
        end

        if enqueue_metadata_cache_worker
          ::Packages::Npm::CreateMetadataCacheWorker.perform_async(project.id, package_name)
        end

        ServiceResponse.success
      end

      private

      def packages
        ::Packages::Npm::PackageFinder.new(
          project: project,
          params: {
            package_name: package_name,
            package_version: params['versions'].keys
          }
        ).execute
      end

      def metadatum_attributes(package)
        package_json = params.dig('versions', package.version)
        return unless package_json.key?('deprecated')

        # Extract deprecation message for this specific package version
        deprecation_msg = package_json['deprecated']

        npm_metadatum = package.npm_metadatum || package.build_npm_metadatum(package_json: package_json)
        return if npm_metadatum.persisted? && identical?(npm_metadatum.package_json['deprecated'], deprecation_msg)

        if npm_metadatum.valid?
          updated_package_json = update_package_json(npm_metadatum.package_json, deprecation_msg)
          status = package_status_for(deprecation_msg)

          { package_id: package.id, package_json: updated_package_json, status: status }
        else
          Gitlab::ErrorTracking.track_exception(
            ActiveRecord::RecordInvalid.new(npm_metadatum),
            class: self.class.name,
            package_id: package.id
          )

          nil
        end
      end

      def identical?(package_json_deprecated, deprecation_msg)
        # Both nil or empty string mean "not deprecated"
        both_empty = package_json_deprecated.to_s.empty? && deprecation_msg.to_s.empty?

        package_json_deprecated == deprecation_msg || both_empty
      end

      def update_package_json(package_json, deprecation_msg)
        # Clone to avoid mutating the original hash
        updated_json = package_json.dup

        if deprecation_msg.to_s.empty?
          updated_json.delete('deprecated')
        else
          updated_json['deprecated'] = deprecation_msg
        end

        updated_json
      end

      def package_status_for(deprecation_msg)
        return ::Packages::Package.statuses[:default] if deprecation_msg.to_s.empty?

        ::Packages::Package.statuses[:deprecated]
      end

      def package_name
        params['name']
      end
      strong_memoize_attr :package_name
    end
  end
end
