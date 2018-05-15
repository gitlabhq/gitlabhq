module Gitlab
  module HashedStorage
    module RakeHelper
      def self.batch_size
        ENV.fetch('BATCH', 200).to_i
      end

      def self.project_id_batches(&block)
        Project.with_unmigrated_storage.in_batches(of: batch_size, start: ENV['ID_FROM'], finish: ENV['ID_TO']) do |relation| # rubocop: disable Cop/InBatches
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
        relation_count = relation_summary(relation_name, relation)

        projects = relation.with_route
        limit = ENV.fetch('LIMIT', 500).to_i

        return unless relation_count > 0

        $stdout.puts "  ! Displaying first #{limit} #{relation_name}..." if relation_count > limit

        counter = 0
        projects.find_in_batches(batch_size: batch_size) do |batch|
          batch.each do |project|
            counter += 1

            $stdout.puts "  - #{project.full_path} (id: #{project.id})".color(:red)

            return if counter >= limit # rubocop:disable Lint/NonLocalExitFromIterator, Cop/AvoidReturnFromBlocks
          end
        end
      end

      def self.attachments_list(relation_name, relation)
        relation_count = relation_summary(relation_name, relation)

        limit = ENV.fetch('LIMIT', 500).to_i

        return unless relation_count > 0

        $stdout.puts "  ! Displaying first #{limit} #{relation_name}..." if relation_count > limit

        counter = 0
        relation.find_in_batches(batch_size: batch_size) do |batch|
          batch.each do |upload|
            counter += 1

            $stdout.puts "  - #{upload.path} (id: #{upload.id})".color(:red)

            return if counter >= limit # rubocop:disable Lint/NonLocalExitFromIterator, Cop/AvoidReturnFromBlocks
          end
        end
      end
    end
  end
end
