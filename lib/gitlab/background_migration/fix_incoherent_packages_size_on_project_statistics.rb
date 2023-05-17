# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # A migration that will:
    # * get all project statistics where packages_size is non zero
    # * check the coherence with the related package files
    # * fix non coherent packages_size values
    class FixIncoherentPackagesSizeOnProjectStatistics < BatchedMigrationJob
      MIGRATOR = 'FixIncoherentPackagesSizeOnProjectStatistics'

      feature_category :package_registry

      operation_name :fix_incorrect_packages_size

      def perform
        each_sub_batch do |sub_batch|
          fix_packages_size(sub_batch)
        end
      end

      private

      def fix_packages_size(project_statistics)
        statistics_table = FixIncoherentPackagesSizeOnProjectStatistics::ProjectStatistics.arel_table
        from = [
          statistics_table,
          FixIncoherentPackagesSizeOnProjectStatistics::PackageFile.sum_query.arel.lateral.as('size_sum')
        ]
        size_sum_table = ::Arel::Table.new(:size_sum)

        project_statistics.select(:id, :project_id, :packages_size, size_sum_table[:total])
          .from(from)
          .where.not(statistics_table[:packages_size].eq(size_sum_table[:total]))
          .each do |stat|
          increment = stat[:total].to_i - stat[:packages_size] - buffered_update(stat)
          next if increment == 0

          ::Gitlab::BackgroundMigration::Logger.info(
            migrator: MIGRATOR,
            project_id: stat[:project_id],
            old_size: stat[:packages_size],
            new_size: stat[:total].to_i
          )

          stat.becomes(FixIncoherentPackagesSizeOnProjectStatistics::ProjectStatistics) # rubocop:disable Cop/AvoidBecomes
              .increment(increment)
        end
      end

      def buffered_update(stat)
        key = "project:{#{stat[:project_id]}}:counters:ProjectStatistics:#{stat[:id]}:packages_size"

        Gitlab::Redis::SharedState.with do |redis|
          redis.get(key).to_i
        end
      end

      # rubocop:disable Style/Documentation
      class ProjectStatistics < ::ApplicationRecord
        self.table_name = 'project_statistics'

        def increment(amount)
          FixIncoherentPackagesSizeOnProjectStatistics::BufferedCounter.new(self).increment(amount)
        end
      end

      class Package < ::ApplicationRecord
        self.table_name = 'packages_packages'

        has_many :package_files,
          class_name: '::Gitlab::BackgroundMigration::FixIncoherentPackagesSizeOnProjectStatistics::PackageFile'
      end

      class PackageFile < ::ApplicationRecord
        self.table_name = 'packages_package_files'

        belongs_to :package,
          class_name: '::Gitlab::BackgroundMigration::FixIncoherentPackagesSizeOnProjectStatistics::Package'

        def self.sum_query
          packages = FixIncoherentPackagesSizeOnProjectStatistics::Package.arel_table
          stats = FixIncoherentPackagesSizeOnProjectStatistics::ProjectStatistics.arel_table

          joins(:package)
            .where(packages[:project_id].eq(stats[:project_id]))
            .where.not(size: nil)
            .select('SUM(packages_package_files.size) as total')
        end
      end

      class BufferedCounter
        WORKER_DELAY = 10.minutes

        def initialize(stat)
          @stat = stat
        end

        def key
          "project:{#{@stat.project_id}}:counters:ProjectStatistics:#{@stat.id}:packages_size"
        end

        def increment(amount)
          Gitlab::Redis::SharedState.with do |redis|
            redis.incrby(key, amount)
          end

          FlushCounterIncrementsWorker.perform_in(
            WORKER_DELAY,
            'ProjectStatistics',
            @stat.id,
            :packages_size
          )
        end
      end
      # rubocop:enable Style/Documentation
    end
  end
end
