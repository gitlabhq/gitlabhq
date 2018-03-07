# frozen_string_literal: true
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/LineLength
# rubocop:disable Metrics/AbcSize
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class DeserializeMergeRequestDiffsAndCommits
      attr_reader :diff_ids, :commit_rows, :file_rows

      class Error < StandardError
        def backtrace
          cause.backtrace
        end
      end

      class MergeRequestDiff < ActiveRecord::Base
        self.table_name = 'merge_request_diffs'
      end

      BUFFER_ROWS = 1000
      DIFF_FILE_BUFFER_ROWS = 100

      def perform(start_id, stop_id)
        merge_request_diffs = MergeRequestDiff
                               .select(:id, :st_commits, :st_diffs)
                               .where('st_commits IS NOT NULL OR st_diffs IS NOT NULL')
                               .where(id: start_id..stop_id)

        reset_buffers!

        merge_request_diffs.each do |merge_request_diff|
          commits, files = single_diff_rows(merge_request_diff)

          diff_ids << merge_request_diff.id
          commit_rows.concat(commits)
          file_rows.concat(files)

          if diff_ids.length > BUFFER_ROWS ||
              commit_rows.length > BUFFER_ROWS ||
              file_rows.length > DIFF_FILE_BUFFER_ROWS

            flush_buffers!
          end
        end

        flush_buffers!
      rescue => e
        Rails.logger.info("#{self.class.name}: failed for IDs #{merge_request_diffs.map(&:id)} with #{e.class.name}")

        raise Error.new(e.inspect)
      end

      private

      def reset_buffers!
        @diff_ids = []
        @commit_rows = []
        @file_rows = []
      end

      def flush_buffers!
        if diff_ids.any?
          commit_rows.each_slice(BUFFER_ROWS).each do |commit_rows_slice|
            bulk_insert('merge_request_diff_commits', commit_rows_slice)
          end

          file_rows.each_slice(DIFF_FILE_BUFFER_ROWS).each do |file_rows_slice|
            bulk_insert('merge_request_diff_files', file_rows_slice)
          end

          MergeRequestDiff.where(id: diff_ids).update_all(st_commits: nil, st_diffs: nil)
        end

        reset_buffers!
      end

      def bulk_insert(table, rows)
        Gitlab::Database.bulk_insert(table, rows)
      rescue ActiveRecord::RecordNotUnique
        ids = rows.map { |row| row[:merge_request_diff_id] }.uniq.sort

        Rails.logger.info("#{self.class.name}: rows inserted twice for IDs #{ids}")
      end

      def single_diff_rows(merge_request_diff)
        sha_attribute = Gitlab::Database::ShaAttribute.new
        commits = YAML.load(merge_request_diff.st_commits) rescue []
        commits ||= []

        commit_rows = commits.map.with_index do |commit, index|
          commit_hash = commit.to_hash.with_indifferent_access.except(:parent_ids)
          sha = commit_hash.delete(:id)

          commit_hash.merge(
            merge_request_diff_id: merge_request_diff.id,
            relative_order: index,
            sha: sha_attribute.type_cast_for_database(sha)
          )
        end

        diffs = YAML.load(merge_request_diff.st_diffs) rescue []
        diffs = [] unless valid_raw_diffs?(diffs)

        file_rows = diffs.map.with_index do |diff, index|
          diff_hash = diff.to_hash.with_indifferent_access.merge(
            binary: false,
            merge_request_diff_id: merge_request_diff.id,
            relative_order: index
          )

          diff_hash.tap do |hash|
            diff_text = hash[:diff]

            hash[:too_large] = !!hash[:too_large]

            hash[:a_mode] ||= guess_mode(hash[:new_file], hash[:diff])
            hash[:b_mode] ||= guess_mode(hash[:deleted_file], hash[:diff])

            # Compatibility with old diffs created with Psych.
            if diff_text.encoding == Encoding::BINARY && !diff_text.ascii_only?
              hash[:binary] = true
              hash[:diff] = [diff_text].pack('m0')
            end
          end
        end

        [commit_rows, file_rows]
      end

      # This doesn't have to be 100% accurate, because it's only used for
      # display - it won't change file modes in the repository. Submodules are
      # created as 600, regular files as 644.
      def guess_mode(file_missing, diff)
        return '0' if file_missing

        diff.include?('Subproject commit') ? '160000' : '100644'
      end

      # Unlike MergeRequestDiff#valid_raw_diff?, don't count Rugged objects as
      # valid, because we don't render them usefully anyway.
      def valid_raw_diffs?(diffs)
        return false unless diffs.respond_to?(:each)

        diffs.all? { |diff| diff.is_a?(Hash) }
      end
    end
  end
end
