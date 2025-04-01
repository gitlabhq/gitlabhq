# frozen_string_literal: true

module Gitlab
  module Database
    class DeduplicateCiTags
      TAGGING_BATCH_SIZE = 10_000
      TAG_BATCH_SIZE = 10_000
      TAGS_INDEX_NAME = 'index_tags_on_name'

      def initialize(logger:, dry_run:)
        @logger = logger
        @dry_run = dry_run
      end

      def execute
        logger.info "DRY RUN:" if dry_run

        good_tag_ids_query = ::Ci::Tag.group(:name).select('MIN(id) AS id')

        bad_tag_map = ::Ci::Tag
          .id_not_in(good_tag_ids_query)
          .pluck(:id, :name)
          .to_h

        if bad_tag_map.empty?
          logger.info "No duplicate tags found in ci database"
          return
        end

        logger.info "Deduplicating #{bad_tag_map.count} #{'tag'.pluralize(bad_tag_map.count)} for ci database"

        bad_tag_ids = bad_tag_map.keys
        good_tags_name_id_map = ::Ci::Tag.id_in(good_tag_ids_query).pluck(:name, :id).to_h
        tag_remap = bad_tag_map.transform_values { |name| good_tags_name_id_map[name] }

        deduplicate_ci_tags(bad_tag_ids, tag_remap)

        logger.info 'Done'
      end

      private

      attr_reader :logger, :dry_run

      def deduplicate_ci_tags(bad_tag_ids, tag_remap)
        ::Ci::PendingBuild.each_batch do |batch|
          changes = batch
            .filter { |pending_build| pending_build.tag_ids.intersect?(bad_tag_ids) }
            .map do |pending_build|
              {
                **pending_build.slice(:id, :build_id, :partition_id, :project_id),
                tag_ids: pending_build.tag_ids.map { |tag_id| tag_remap.fetch(tag_id, tag_id) }
              }
            end

          ::Ci::PendingBuild.upsert_all(changes, unique_by: :id, update_only: [:tag_ids]) unless dry_run

          logger.info("Updated tag_ids on a batch of #{batch.count} #{::Ci::PendingBuild.table_name} records")
          sleep(1)
        end

        deduplicate_ci_taggings(bad_tag_ids, tag_remap)

        ::Ci::Tag.include EachBatch
        ::Ci::Tag.id_in(bad_tag_ids).each_batch(of: TAG_BATCH_SIZE) do |batch|
          count = dry_run ? batch.count : batch.delete_all
          logger.info "Deleted batch of #{count} #{'tag'.pluralize(count)}"
        end

        unless dry_run
          ::Ci::Tag.connection.exec_query("DROP INDEX IF EXISTS #{TAGS_INDEX_NAME};")
          ::Ci::Tag.connection.exec_query(<<~SQL)
            CREATE UNIQUE INDEX #{TAGS_INDEX_NAME} ON #{::Ci::Tag.table_name} USING btree (name);
          SQL
        end

        logger.info "Recreated #{TAGS_INDEX_NAME}"
      end

      def deduplicate_ci_taggings(bad_tag_ids, tag_remap)
        tagging_models = [::Ci::BuildTag, ::Ci::RunnerTagging]

        tagging_models.each do |tagging_model|
          tagging_model.include EachBatch

          delete_duplicate_taggings(tagging_model, tag_remap)

          bad_tag_ids.each do |bad_tag_id|
            tagging_model.where(tag_id: bad_tag_id).each_batch(of: TAGGING_BATCH_SIZE) do |batch|
              batch.update_all(tag_id: tag_remap.fetch(bad_tag_id)) unless dry_run

              logger.info(
                "Updated tag_id #{bad_tag_id} on #{tagging_model.table_name} records to #{tag_remap.fetch(bad_tag_id)}"
              )
            end
          end
        end
      end

      def taggings_with_fk(model_record)
        case model_record
        when ::Ci::BuildTag
          model_record.class.where(build_id: model_record.build_id)
        when ::Ci::RunnerTagging
          model_record.class.where(runner_id: model_record.runner_id)
        end
      end

      def delete_duplicate_taggings(tagging_model, tag_remap)
        tagging_model.where(tag_id: tag_remap.keys).each_batch(of: TAGGING_BATCH_SIZE) do |batch|
          batch.each do |bad_tag_id_row|
            existing_tag_id = tag_remap.fetch(bad_tag_id_row.tag_id)

            next unless taggings_with_fk(bad_tag_id_row).where(tag_id: existing_tag_id).exists?
            next if dry_run

            taggings_with_fk(bad_tag_id_row).where(tag_id: bad_tag_id_row.tag_id).delete_all
          end
        end
      end
    end
  end
end

Gitlab::Database::DeduplicateCiTags.prepend_mod
