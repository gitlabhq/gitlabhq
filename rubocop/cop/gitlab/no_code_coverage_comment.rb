# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Discourages the use of `# :nocov:` to exclude code from coverage report.
      #
      # The nocov token can be configured via `CommentToken` option and defaults
      # to `'nocov'`.
      #
      # @example CommentToken: 'nocov' (default)
      #
      #   # bad
      #   # :nocov:
      #   def method
      #   end
      #   # :nocov:
      #
      #   # good
      #   def method
      #   end
      #
      class NoCodeCoverageComment < RuboCop::Cop::Base
        include RangeHelp

        MSG = 'The use of %<nocov_comment>s is discouraged. All code must have tests. See https://docs.gitlab.com/ee/development/contributing/merge_request_workflow.html#testing'

        DEFAULT_COMMENT_TOKEN = 'nocov'

        def on_new_investigation
          super

          nocov_token = cop_config.fetch('CommentToken', DEFAULT_COMMENT_TOKEN)
          nocov_comment = ":#{nocov_token}:"
          # See https://github.com/simplecov-ruby/simplecov/blob/v0.21.2/lib/simplecov/lines_classifier.rb#L16
          regexp = /^(?:\s*)#(?:\s*)(?::#{nocov_token}:)/

          processed_source.comments.each do |comment|
            register_offense(comment, nocov_comment) if regexp.match?(comment.text)
          end
        end

        private

        def register_offense(comment, nocov_comment)
          range = range_of_offense(comment, nocov_comment)
          message = format(MSG, nocov_comment: nocov_comment)

          add_offense(range, message: message)
        end

        def range_of_offense(comment, name)
          start_pos = comment_start(comment) + token_indentation(comment, name)
          range_between(start_pos, start_pos + name.size)
        end

        def comment_start(comment)
          comment.loc.expression.begin_pos
        end

        def token_indentation(comment, name)
          comment.text.index(name)
        end
      end
    end
  end
end
