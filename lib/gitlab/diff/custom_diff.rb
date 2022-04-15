# frozen_string_literal: true
module Gitlab
  module Diff
    module CustomDiff
      RENDERED_TIMEOUT_BACKGROUND = 20.seconds
      RENDERED_TIMEOUT_FOREGROUND = 1.5.seconds
      BACKGROUND_EXECUTION = 'background'
      FOREGROUND_EXECUTION = 'foreground'
      LOG_IPYNBDIFF_GENERATED = 'IPYNB_DIFF_GENERATED'
      LOG_IPYNBDIFF_TIMEOUT = 'IPYNB_DIFF_TIMEOUT'
      LOG_IPYNBDIFF_INVALID = 'IPYNB_DIFF_INVALID'

      class << self
        def preprocess_before_diff(path, old_blob, new_blob)
          return unless path.ends_with? '.ipynb'

          Timeout.timeout(timeout_time) do
            transformed_diff(old_blob&.data, new_blob&.data)&.tap do
              transformed_for_diff(new_blob, old_blob)
              log_event(LOG_IPYNBDIFF_GENERATED)
            end
          end
        rescue Timeout::Error => e
          rendered_timeout.increment(source: execution_source)
          log_event(LOG_IPYNBDIFF_TIMEOUT, e)
        rescue IpynbDiff::InvalidNotebookError, IpynbDiff::InvalidTokenError => e
          log_event(LOG_IPYNBDIFF_INVALID, e)
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

        def rendered_timeout
          @rendered_timeout ||= Gitlab::Metrics.counter(
            :ipynb_semantic_diff_timeouts_total,
            'Counts the times notebook rendering timed out'
          )
        end

        def timeout_time
          Gitlab::Runtime.sidekiq? ? RENDERED_TIMEOUT_BACKGROUND : RENDERED_TIMEOUT_FOREGROUND
        end

        def execution_source
          Gitlab::Runtime.sidekiq? ? BACKGROUND_EXECUTION : FOREGROUND_EXECUTION
        end

        def log_event(message, error = nil)
          Gitlab::AppLogger.info({ message: message })
          Gitlab::ErrorTracking.track_exception(error) if error
          nil
        end
      end
    end
  end
end
