# frozen_string_literal: true

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

      def self.using_ranges?
        !range_from.nil? && !range_to.nil?
      end

      def self.range_single_item?
        using_ranges? && range_from == range_to
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def self.project_id_batches_migration(&block)
        Project.with_unmigrated_storage.in_batches(of: batch_size, start: range_from, finish: range_to) do |relation| # rubocop: disable Cop/InBatches
          ids = relation.pluck(:id)

          yield ids.min, ids.max
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def self.project_id_batches_rollback(&block)
        Project.with_storage_feature(:repository).in_batches(of: batch_size, start: range_from, finish: range_to) do |relation| # rubocop: disable Cop/InBatches
          ids = relation.pluck(:id)

          yield ids.min, ids.max
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def self.legacy_attachments_relation
        Upload.inner_join_local_uploads_projects.merge(Project.without_storage_feature(:attachments))
      end

      def self.hashed_attachments_relation
        Upload.inner_join_local_uploads_projects.merge(Project.with_storage_feature(:attachments))
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

      # rubocop: disable CodeReuse/ActiveRecord
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
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
