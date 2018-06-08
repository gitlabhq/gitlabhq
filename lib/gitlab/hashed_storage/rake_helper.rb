module Gitlab
  module HashedStorage
    module RakeHelper
      def self.batch_size
        ENV.fetch('BATCH', 200).to_i
      end

      def self.listing_limit
        ENV.fetch('LIMIT', 500).to_i
      end

      def self.range_from
        ENV['ID_FROM']
      end

      def self.range_to
        ENV['ID_TO']
      end

      def self.range_single_item?
        !range_from.nil? && range_from == range_to
      end

      def self.project_id_batches(&block)
        Project.with_unmigrated_storage.in_batches(of: batch_size, start: range_from, finish: range_to) do |relation| # rubocop: disable Cop/InBatches
          ids = relation.pluck(:id)

          yield ids.min, ids.max
        end
      end

      def self.legacy_attachments_relation
        Upload.joins(<<~SQL).where('projects.storage_version < :version OR projects.storage_version IS NULL', version: Project::HASHED_STORAGE_FEATURES[:attachments])
          JOIN projects
            ON (uploads.model_type='Project' AND uploads.model_id=projects.id)
        SQL
      end

      def self.hashed_attachments_relation
        Upload.joins(<<~SQL).where('projects.storage_version >= :version', version: Project::HASHED_STORAGE_FEATURES[:attachments])
          JOIN projects
          ON (uploads.model_type='Project' AND uploads.model_id=projects.id)
        SQL
      end

      def self.relation_summary(relation_name, relation)
        relation_count = relation.count
        $stdout.puts "* Found #{relation_count} #{relation_name}".color(:green)

        relation_count
      end

      def self.projects_list(relation_name, relation)
        listing(relation_name, relation.with_route) do |project|
          $stdout.puts "  - #{project.full_path} (id: #{project.id})".color(:red)
        end
      end

      def self.attachments_list(relation_name, relation)
        listing(relation_name, relation) do |upload|
          $stdout.puts "  - #{upload.path} (id: #{upload.id})".color(:red)
        end
      end

      def self.listing(relation_name, relation)
        relation_count = relation_summary(relation_name, relation)
        return unless relation_count > 0

        limit = listing_limit

        if relation_count > limit
          $stdout.puts "  ! Displaying first #{limit} #{relation_name}..."
        end

        relation.find_each(batch_size: batch_size).with_index do |element, index|
          yield element

          break if index + 1 >= limit
        end
      end
    end
  end
end
