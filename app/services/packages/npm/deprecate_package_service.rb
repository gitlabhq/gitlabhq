# frozen_string_literal: true

module Packages
  module Npm
    class DeprecatePackageService < BaseService
      DeprecatedMetadatum = Struct.new(:package_id, :message, :attributes)
      BATCH_SIZE = 50

      def initialize(project, params)
        super(project, nil, params)
        @enqueue_metadata_cache_worker = false
      end

      def execute
        packages.select(:id, :version, :package_type).each_batch(of: BATCH_SIZE) do |relation|
          deprecated_metadata = handle_batch(relation)
          update_or_create_metadata(deprecated_metadata)
        end

        if enqueue_metadata_cache_worker
          ::Packages::Npm::CreateMetadataCacheWorker.perform_async(project.id, params['package_name'])
        end

        ServiceResponse.success
      end

      private

      attr_accessor :enqueue_metadata_cache_worker

      def packages
        ::Packages::Npm::PackageFinder.new(
          project: project,
          params: {
            package_name: params['package_name'],
            package_version: params['versions'].keys
          }
        ).execute
      end

      def handle_batch(relation)
        relation
          .preload_npm_metadatum
          .filter_map { |package| deprecate(package) }
      end

      def deprecate(package)
        package_json = params.dig('versions', package.version)
        deprecation_message = package_json&.dig('deprecated')
        return if deprecation_message.nil?

        npm_metadatum = package.npm_metadatum || package.build_npm_metadatum(package_json: package_json)
        return if npm_metadatum.persisted? && identical?(npm_metadatum.package_json['deprecated'], deprecation_message)

        DeprecatedMetadatum.new.tap do |deprecated|
          if npm_metadatum.persisted?
            deprecated.package_id = package.id
            deprecated.message = deprecation_message
          elsif npm_metadatum.valid?
            deprecated.attributes = npm_metadatum.attributes
          else
            Gitlab::ErrorTracking.track_exception(
              ActiveRecord::RecordInvalid.new(npm_metadatum),
              class: self.class.name,
              package_id: package.id
            )
            break # to return nil instead of an empty struct
          end
        end
      end

      def identical?(package_json_deprecated, deprecation_message)
        package_json_deprecated == deprecation_message ||
          (package_json_deprecated.nil? && deprecation_message.empty?)
      end

      def update_or_create_metadata(deprecated_metadata)
        return if deprecated_metadata.empty?

        to_update, to_create = deprecated_metadata.partition(&:message)

        if to_update.any?
          ::Packages::Npm::Metadatum
            .package_id_in(to_update.map(&:package_id))
            .update_all(update_clause(to_update.first.message))
        end

        ::Packages::Npm::Metadatum.insert_all(to_create.map(&:attributes), returning: false) if to_create.any?

        self.enqueue_metadata_cache_worker = true
      end

      def update_clause(deprecation_message)
        if deprecation_message.empty?
          "package_json = package_json - 'deprecated'"
        else
          ["package_json = jsonb_set(package_json, '{deprecated}', ?)", deprecation_message.to_json]
        end
      end
    end
  end
end
