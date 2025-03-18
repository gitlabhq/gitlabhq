# frozen_string_literal: true

module Gitlab
  module Git
    class BlobPairsDiffs
      def initialize(repository)
        @repository = repository
        @raw_repository = repository.raw_repository
      end

      def diffs_by_changed_paths(diff_refs, offset = 0, batch_size = 30)
        changed_paths = @raw_repository.find_changed_paths(
          [Gitlab::Git::DiffTree.new(diff_refs.base_sha, diff_refs.head_sha)],
          find_renames: true
        )

        changed_paths.drop(offset).each_slice(batch_size) do |batched_changed_paths|
          blob_pairs = batched_changed_paths.reject(&:submodule_change?).map do |changed_path|
            Gitaly::DiffBlobsRequest::BlobPair.new(
              left_blob: changed_path.old_blob_id,
              right_blob: changed_path.new_blob_id
            )
          end

          result = diff_files_by_blob_pairs(blob_pairs, batched_changed_paths, diff_refs)
          yield result if block_given?
        end
      end

      private

      def diff_files_by_blob_pairs(blob_pairs, changed_paths, diff_refs)
        non_submodule_paths = changed_paths.reject(&:submodule_change?)
        diff_blobs = @raw_repository.diff_blobs(blob_pairs, patch_bytes_limit: Gitlab::Git::Diff.patch_hard_limit_bytes)

        changed_diff_blobs = diff_blobs.zip(non_submodule_paths)
        changed_diff_blobs = changed_diff_blobs.reject { |diff_blob, path| diff_blob.nil? || path.nil? }

        diff_blob_lookup = changed_diff_blobs.to_h { |diff_blob, path| [path.path, diff_blob] }

        changed_paths.filter_map do |changed_path|
          if changed_path.submodule_change?
            create_diff(changed_path, diff_refs, diff: generate_submodule_diff(changed_path))
          else
            diff_blob = diff_blob_lookup[changed_path.path]
            next if diff_blob.nil?

            create_diff(changed_path, diff_refs, diff: diff_blob.patch, too_large: diff_blob.over_patch_bytes_limit)
          end
        end.compact
      end

      def create_diff(changed_path, diff_refs, options = {})
        diff_options = {
          new_path: changed_path.path,
          old_path: changed_path.old_path,
          a_mode: changed_path.old_mode,
          b_mode: changed_path.new_mode,
          new_file: changed_path.new_file?,
          renamed_file: changed_path.renamed_file?,
          deleted_file: changed_path.deleted_file?
        }.merge(options)

        diff = Gitlab::Git::Diff.new(diff_options)

        Gitlab::Diff::File.new(
          diff,
          repository: @repository,
          diff_refs: diff_refs
        )
      end

      def generate_submodule_diff(changed_path)
        diff_lines = []
        if changed_path.deleted_file? || changed_path.modified_file?
          diff_lines << "- Subproject commit #{changed_path.old_blob_id}"
        end

        if changed_path.new_file? || changed_path.modified_file?
          diff_lines << "+ Subproject commit #{changed_path.new_blob_id}"
        end

        diff_lines.join("\n")
      end
    end
  end
end
