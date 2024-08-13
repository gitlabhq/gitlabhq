# frozen_string_literal: true

module Banzai
  module Filter
    # Add timeout ability to a Banzai filter by wrapping it in a Gitlab::RenderTimeout.
    # This way partial results can be returned, and the entire pipeline
    # is not killed.
    #
    # This should not be used for any filter that must be allowed to complete,
    # like a `ReferenceRedactorFilter` or `SanitizationFilter`
    # It also should not be used when the filter depends on network calls, including
    # PostgreSQL requests.
    # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145679#note_1875831539
    #
    module Concerns
      module TimeoutFilterHandler
        extend ActiveSupport::Concern

        RENDER_TIMEOUT = 2.seconds

        # [TODO] Seeing several complaints about rendering being too complex.
        # https://gitlab.com/gitlab-org/gitlab/-/issues/469683
        # The default 2 seconds seems to be too aggressive at the moment.
        # It can also depend in the hardware that we're running on.
        # So let's make it 5. Currently the overall pipeline timeout
        # (pipeline_timing_check.rb) is set to 5.
        SANITIZATION_RENDER_TIMEOUT = 5.seconds
        COMPLEX_MARKDOWN_MESSAGE =
          <<~HTML
            <p>Rendering aborted due to complexity issues. If this is valid markdown, please feel free to open an issue
            and attach the original markdown to the issue.</p>
          HTML

        def call
          return super if Gitlab::RenderTimeout.banzai_timeout_disabled?

          Gitlab::RenderTimeout.timeout(foreground: render_timeout, background: render_timeout) { super }
        rescue Timeout::Error => e
          class_name = self.class.name.demodulize
          Gitlab::ErrorTracking.track_exception(e, project_id: context[:project]&.id, group_id: context[:group]&.id,
            class_name: class_name)

          # we've timed out, but some work may have already been completed,
          # so return what we can
          returned_timeout_value
        end

        private

        def render_timeout
          return super if defined?(super)

          RENDER_TIMEOUT
        end

        def returned_timeout_value
          return super if defined?(super)

          if is_a?(HTML::Pipeline::TextFilter)
            text
          else
            doc
          end
        end
      end
    end
  end
end
