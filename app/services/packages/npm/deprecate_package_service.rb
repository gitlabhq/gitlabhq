# frozen_string_literal: true

module Packages
  module Npm
    class DeprecatePackageService < BaseService
      Deprecated = Struct.new(:package_id, :message)
      BATCH_SIZE = 50

      def initialize(project, params)
        super(project, nil, params)
      end

      def execute(async: false)
        return ::Packages::Npm::DeprecatePackageWorker.perform_async(project.id, filtered_params) if async

        packages.select(:id, :version).each_batch(of: BATCH_SIZE) do |relation|
          deprecated_metadatum = handle_batch(relation)
          update_metadatum(deprecated_metadatum)
        end
      end

      private

      # To avoid passing the whole metadata to the worker
      def filtered_params
        {
          package_name: params[:package_name],
          versions: params[:versions].transform_values { |version| version.slice(:deprecated) }
        }
      end

      def packages
        ::Packages::Npm::PackageFinder
          .new(params['package_name'], project: project)
          .execute
      end

      def handle_batch(relation)
        relation
          .preload_npm_metadatum
          .filter_map { |package| deprecate(package) }
      end

      def deprecate(package)
        deprecation_message = params.dig('versions', package.version, 'deprecated')
        return if deprecation_message.nil?

        npm_metadatum = package.npm_metadatum
        return if identical?(npm_metadatum.package_json['deprecated'], deprecation_message)

        Deprecated.new(npm_metadatum.package_id, deprecation_message)
      end

      def identical?(package_json_deprecated, deprecation_message)
        package_json_deprecated == deprecation_message ||
          (package_json_deprecated.nil? && deprecation_message.empty?)
      end

      def update_metadatum(deprecated_metadatum)
        return if deprecated_metadatum.empty?

        deprecation_message = deprecated_metadatum.first.message

        ::Packages::Npm::Metadatum
          .package_id_in(deprecated_metadatum.map(&:package_id))
          .update_all(update_clause(deprecation_message))
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
