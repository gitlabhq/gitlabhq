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

          super
        end

        private

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
            head_sha: args[:head_sha]
          ).execute

          raise Gitlab::Graphql::Errors::ArgumentError, resolve_result.message if resolve_result.error?

          Gitlab::Diff::Position.new(resolve_result.payload[:position])
        end
      end
    end
  end
end
