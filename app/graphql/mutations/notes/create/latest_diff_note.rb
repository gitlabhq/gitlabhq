# frozen_string_literal: true

module Mutations
  module Notes
    module Create
      class LatestDiffNote < Base
        graphql_name 'CreateLatestDiffNote'
        description 'Creates a diff note on a merge request using minimal parameters. ' \
          'SHAs, file paths, and position type are resolved automatically from the latest merge request diff.'

        argument :file_path,
          GraphQL::Types::String,
          required: true,
          description: 'Path of the file to comment on. For renamed files, either the old or new path can be used.'

        argument :new_line,
          GraphQL::Types::Int,
          required: false,
          description: 'Line number on the new version of the file. ' \
            'Use alone for added lines, with oldLine for unchanged context lines. ' \
            'At least one of newLine or oldLine is required.'

        argument :old_line,
          GraphQL::Types::Int,
          required: false,
          description: 'Line number on the old version of the file. ' \
            'Use alone for removed lines, with newLine for unchanged context lines. ' \
            'At least one of newLine or oldLine is required.'

        argument :end_new_line,
          GraphQL::Types::Int,
          required: false,
          description: 'End line number on the new version of the file for a multiline note. ' \
            'When provided, newLine is required and marks the start of the comment range.'

        argument :end_old_line,
          GraphQL::Types::Int,
          required: false,
          description: 'End line number on the old version of the file for a multiline note. ' \
            'When provided, oldLine is required and marks the start of the comment range.'

        argument :noteable_id,
          ::Types::GlobalIDType[::MergeRequest],
          required: true,
          description: 'Global ID of the merge request to add a diff note to.'

        argument :head_sha,
          GraphQL::Types::String,
          required: true,
          description: 'HEAD SHA of the merge request diff. ' \
            'The request fails if it does not match the current diff, ' \
            'guarding against commenting on a stale diff.'

        def ready?(**args)
          if args.values_at(:old_line, :new_line).compact.blank?
            raise Gitlab::Graphql::Errors::ArgumentError,
              'oldLine or newLine arguments are required'
          end

          validate_line_range!(args)

          super
        end

        private

        def validate_line_range!(args)
          validate_end_line_has_start!(args[:end_new_line], args[:new_line], 'newLine', 'endNewLine')
          validate_end_line_has_start!(args[:end_old_line], args[:old_line], 'oldLine', 'endOldLine')
        end

        def validate_end_line_has_start!(end_line, start_line, start_name, end_name)
          return unless end_line

          unless start_line
            raise Gitlab::Graphql::Errors::ArgumentError,
              "#{start_name} is required when #{end_name} is provided"
          end

          return if end_line > start_line

          raise Gitlab::Graphql::Errors::ArgumentError,
            "#{end_name} must be greater than #{start_name}"
        end

        def create_note_params(noteable, args)
          super.merge({
            type: 'DiffNote',
            position: position(noteable, args),
            merge_request_diff_head_sha: args[:head_sha]
          })
        end

        def position(noteable, args)
          resolve_result = ::MergeRequests::ResolveDiffPositionService.new(
            noteable.project,
            current_user,
            merge_request: noteable,
            file_path: args[:file_path],
            new_line: args[:new_line],
            old_line: args[:old_line],
            end_new_line: args[:end_new_line],
            end_old_line: args[:end_old_line],
            head_sha: args[:head_sha]
          ).execute

          raise Gitlab::Graphql::Errors::ArgumentError, resolve_result.message if resolve_result.error?

          Gitlab::Diff::Position.new(resolve_result.payload[:position])
        end
      end
    end
  end
end
