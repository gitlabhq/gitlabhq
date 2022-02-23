# frozen_string_literal: true
module Gitlab
  module Diff
    module CustomDiff
      class << self
        def preprocess_before_diff(path, old_blob, new_blob)
          return unless path.ends_with? '.ipynb'

          transformed_diff(old_blob&.data, new_blob&.data)&.tap do
            transformed_for_diff(new_blob, old_blob)
            Gitlab::AppLogger.info({ message: 'IPYNB_DIFF_GENERATED' })
          end
        rescue IpynbDiff::InvalidNotebookError, IpynbDiff::InvalidTokenError => e
          Gitlab::ErrorTracking.log_exception(e)
          nil
        end

        def transformed_diff(before, after)
          transformed_diff = IpynbDiff.diff(before, after,
                         raise_if_invalid_nb: true,
                         diffy_opts: { include_diff_info: true }).to_s(:text)

          strip_diff_frontmatter(transformed_diff)
        end

        def transformed_blob_language(blob)
          'md' if transformed_for_diff?(blob)
        end

        def transformed_blob_data(blob)
          if transformed_for_diff?(blob)
            IpynbDiff.transform(blob.data, raise_errors: true, include_frontmatter: false)
          end
        end

        def strip_diff_frontmatter(diff_content)
          diff_content.scan(/.*\n/)[2..]&.join('') if diff_content.present?
        end

        def blobs_with_transformed_diffs
          @blobs_with_transformed_diffs ||= {}
        end

        def transformed_for_diff?(blob)
          blobs_with_transformed_diffs[blob]
        end

        def transformed_for_diff(*blobs)
          blobs.each do |b|
            blobs_with_transformed_diffs[b] = true if b
          end
        end
      end
    end
  end
end
