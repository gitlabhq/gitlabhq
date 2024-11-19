# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfill the normalized_version column in the packages_nuget_metadata table
    class BackfillNugetNormalizedVersion < BatchedMigrationJob
      operation_name :update_all
      feature_category :package_registry

      scope_to ->(relation) { relation.where(normalized_version: nil) }

      class Package < ApplicationRecord
        self.table_name = 'packages_packages'
      end

      class PackagesNugetMetadatum < ApplicationRecord
        self.table_name = 'packages_nuget_metadata'

        LEADING_ZEROES_REGEX = /^(?!0$)0+(?=\d)/

        belongs_to :package
        delegate :version, to: :package, prefix: true

        def set_normalized_version
          return unless package

          self.normalized_version = normalize
        end

        private

        def normalize
          version = remove_leading_zeroes
          version = remove_build_metadata(version)
          version = omit_zero_in_fourth_part(version)
          append_suffix(version)
        end

        def remove_leading_zeroes
          package_version.split('.').map { |part| part.sub(LEADING_ZEROES_REGEX, '') }.join('.')
        end

        def remove_build_metadata(version)
          version.split('+').first.downcase
        end

        def omit_zero_in_fourth_part(version)
          parts = version.split('.')
          parts[3] = nil if parts.fourth == '0' && parts.third.exclude?('-')
          parts.compact.join('.')
        end

        def append_suffix(version)
          version << '.0.0' if version.count('.') == 0
          version << '.0' if version.count('.') == 1
          version
        end
      end

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.select(:package_id).then do |relation|
            connection.execute(update_query(relation))
          end
        end
      end

      private

      def update_query(relation)
        <<-SQL.squish
          UPDATE packages_nuget_metadata
          SET normalized_version = v.normalized_version
          FROM ( VALUES #{package_id_and_normalized_version(relation)} ) AS v(package_id, normalized_version)
          WHERE packages_nuget_metadata.package_id = v.package_id;
        SQL
      end

      def package_id_and_normalized_version(relation)
        packages = Package
                    .where(id: relation.map(&:package_id))
                    .select(:id, :version)
                    .index_by(&:id)

        # We need a new PackagesNugetMetadatum instance to be able to trigger
        # #set_normalized_version method that sets the normalized_version.
        relation.map do |record|
          new_record = PackagesNugetMetadatum.new(record.attributes)
          new_record.package = packages[record.package_id]
          new_record.set_normalized_version
          "(#{record.package_id}, '#{new_record.normalized_version}')"
        end.join(', ')
      end
    end
  end
end
