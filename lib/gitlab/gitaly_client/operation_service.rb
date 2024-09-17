# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class OperationService
      include Gitlab::EncodingHelper
      include WithFeatureFlagActors

      MAX_MSG_SIZE = 128.kilobytes.freeze

      CUSTOM_HOOK_FALLBACK_MESSAGE = 'Prevented by server hooks'

      def initialize(repository)
        @gitaly_repo = repository.gitaly_repository
        @repository = repository

        self.repository_actor = repository
      end

      def rm_tag(tag_name, user)
        request = Gitaly::UserDeleteTagRequest.new(
          repository: @gitaly_repo,
          tag_name: encode_binary(tag_name),
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly
        )

        response = gitaly_client_call(@repository.storage, :operation_service, :user_delete_tag, request, timeout: GitalyClient.long_timeout)

        if pre_receive_error = response.pre_receive_error.presence
          raise Gitlab::Git::PreReceiveError, pre_receive_error
        end
      end

      def add_tag(tag_name, user, target, message)
        request = Gitaly::UserCreateTagRequest.new(
          repository: @gitaly_repo,
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          tag_name: encode_binary(tag_name),
          target_revision: encode_binary(target),
          message: encode_binary(message.to_s),
          timestamp: Google::Protobuf::Timestamp.new(seconds: Time.now.utc.to_i)
        )

        response = gitaly_client_call(@repository.storage, :operation_service, :user_create_tag, request, timeout: GitalyClient.long_timeout)

        Gitlab::Git::Tag.new(@repository, response.tag)
      rescue GRPC::BadStatus => e
        detailed_error = GitalyClient.decode_detailed_error(e)

        case detailed_error.try(:error)
        when :access_check
          access_check_error = detailed_error.access_check
          # These messages were returned from internal/allowed API calls
          raise Gitlab::Git::PreReceiveError.new(fallback_message: access_check_error.error_message)
        when :custom_hook
          raise Gitlab::Git::PreReceiveError.new(custom_hook_error_message(detailed_error.custom_hook),
            fallback_message: CUSTOM_HOOK_FALLBACK_MESSAGE)
        when :reference_exists
          raise Gitlab::Git::Repository::TagExistsError
        else
          if e.code == GRPC::Core::StatusCodes::FAILED_PRECONDITION
            raise Gitlab::Git::Repository::InvalidRef, e
          end

          raise
        end
      end

      def user_create_branch(branch_name, user, start_point)
        request = Gitaly::UserCreateBranchRequest.new(
          repository: @gitaly_repo,
          branch_name: encode_binary(branch_name),
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          start_point: encode_binary(start_point)
        )
        response = gitaly_client_call(@repository.storage, :operation_service,
          :user_create_branch, request, timeout: GitalyClient.long_timeout)

        branch = response.branch
        return unless branch

        target_commit = Gitlab::Git::Commit.decorate(@repository, branch.target_commit)
        Gitlab::Git::Branch.new(@repository, branch.name, target_commit.id, target_commit)
      rescue GRPC::BadStatus => e
        detailed_error = GitalyClient.decode_detailed_error(e)

        case detailed_error.try(:error)
        when :custom_hook
          raise Gitlab::Git::PreReceiveError.new(custom_hook_error_message(detailed_error.custom_hook),
            fallback_message: CUSTOM_HOOK_FALLBACK_MESSAGE)
        else
          if e.code == GRPC::Core::StatusCodes::FAILED_PRECONDITION
            raise Gitlab::Git::Repository::InvalidRef, e
          end

          raise
        end
      end

      def user_update_branch(branch_name, user, newrev, oldrev)
        request = Gitaly::UserUpdateBranchRequest.new(
          repository: @gitaly_repo,
          branch_name: encode_binary(branch_name),
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          newrev: encode_binary(newrev),
          oldrev: encode_binary(oldrev)
        )

        response = gitaly_client_call(@repository.storage, :operation_service,
          :user_update_branch, request, timeout: GitalyClient.long_timeout)

        if pre_receive_error = response.pre_receive_error.presence
          raise Gitlab::Git::PreReceiveError, pre_receive_error
        end
      end

      def user_delete_branch(branch_name, user, target_sha: nil)
        request = Gitaly::UserDeleteBranchRequest.new(
          repository: @gitaly_repo,
          branch_name: encode_binary(branch_name),
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          expected_old_oid: target_sha
        )

        gitaly_client_call(@repository.storage, :operation_service,
          :user_delete_branch, request, timeout: GitalyClient.long_timeout)
      rescue GRPC::InvalidArgument => ex
        raise Gitlab::Git::CommandError, ex
      rescue GRPC::BadStatus => e
        detailed_error = GitalyClient.decode_detailed_error(e)

        case detailed_error.try(:error)
        when :custom_hook
          raise Gitlab::Git::PreReceiveError.new(custom_hook_error_message(detailed_error.custom_hook),
            fallback_message: CUSTOM_HOOK_FALLBACK_MESSAGE)
        else
          raise
        end
      end

      def user_merge_to_ref(user, source_sha:, branch:, target_ref:, message:, first_parent_ref:, expected_old_oid: "")
        request = Gitaly::UserMergeToRefRequest.new(
          repository: @gitaly_repo,
          source_sha: source_sha,
          branch: encode_binary(branch),
          target_ref: encode_binary(target_ref),
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          message: encode_binary(message),
          first_parent_ref: encode_binary(first_parent_ref),
          expected_old_oid: expected_old_oid,
          timestamp: Google::Protobuf::Timestamp.new(seconds: Time.now.utc.to_i)
        )

        response = gitaly_client_call(@repository.storage, :operation_service,
          :user_merge_to_ref, request, timeout: GitalyClient.long_timeout)

        response.commit_id
      end

      def user_merge_branch(user, source_sha:, target_branch:, message:, target_sha: nil)
        request_enum = QueueEnumerator.new
        response_enum = gitaly_client_call(
          @repository.storage,
          :operation_service,
          :user_merge_branch,
          request_enum.each,
          timeout: GitalyClient.long_timeout
        )

        request_enum.push(
          Gitaly::UserMergeBranchRequest.new(
            repository: @gitaly_repo,
            user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
            commit_id: source_sha,
            branch: encode_binary(target_branch),
            expected_old_oid: target_sha,
            message: encode_binary(message),
            timestamp: Google::Protobuf::Timestamp.new(seconds: Time.now.utc.to_i)
          )
        )

        yield response_enum.next.commit_id

        request_enum.push(Gitaly::UserMergeBranchRequest.new(apply: true))
        request_enum.close

        second_response = response_enum.next

        branch_update = second_response.branch_update
        return if branch_update.nil?
        raise Gitlab::Git::CommitError, 'failed to apply merge to branch' unless branch_update.commit_id.present?

        consume_final_message(response_enum)

        Gitlab::Git::OperationService::BranchUpdate.from_gitaly(branch_update)
      rescue GRPC::BadStatus => e
        detailed_error = GitalyClient.decode_detailed_error(e)

        case detailed_error.try(:error)
        when :access_check
          access_check_error = detailed_error.access_check
          # These messages were returned from internal/allowed API calls
          raise Gitlab::Git::PreReceiveError.new(fallback_message: access_check_error.error_message)
        when :custom_hook
          raise Gitlab::Git::PreReceiveError.new(custom_hook_error_message(detailed_error.custom_hook),
            fallback_message: CUSTOM_HOOK_FALLBACK_MESSAGE)
        when :reference_update
          # We simply ignore any reference update errors which are typically an
          # indicator of multiple RPC calls trying to update the same reference
          # at the same point in time.
        else
          raise
        end
      ensure
        request_enum.close
      end

      def user_ff_branch(user, source_sha:, target_branch:, target_sha: nil)
        request = Gitaly::UserFFBranchRequest.new(
          repository: @gitaly_repo,
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          commit_id: source_sha,
          branch: encode_binary(target_branch),
          expected_old_oid: target_sha
        )

        response = gitaly_client_call(
          @repository.storage,
          :operation_service,
          :user_ff_branch,
          request,
          timeout: GitalyClient.long_timeout
        )

        if response.pre_receive_error.present?
          raise Gitlab::Git::PreReceiveError.new(response.pre_receive_error, fallback_message: "pre-receive hook failed.")
        end

        Gitlab::Git::OperationService::BranchUpdate.from_gitaly(response.branch_update)
      rescue GRPC::BadStatus => e
        detailed_error = GitalyClient.decode_detailed_error(e)

        case detailed_error.try(:error)
        when :custom_hook
          raise Gitlab::Git::PreReceiveError.new(custom_hook_error_message(detailed_error.custom_hook),
            fallback_message: CUSTOM_HOOK_FALLBACK_MESSAGE)
        when :reference_update
          # Historically UserFFBranch returned a successful response with a missing BranchUpdate if
          # updating the reference failed. The RPC has been updated to return a bad status when the
          # reference update fails. Match the previous behavior until call sites have been adapted.
          nil
        else
          if e.code == GRPC::Core::StatusCodes::FAILED_PRECONDITION
            raise Gitlab::Git::CommitError, e
          end

          raise
        end
      end

      # rubocop:disable Metrics/ParameterLists
      def user_cherry_pick(
        user:, commit:, branch_name:, message:,
        start_branch_name:, start_repository:, author_name: nil, author_email: nil, dry_run: false, target_sha: nil)

        request = Gitaly::UserCherryPickRequest.new(
          repository: @gitaly_repo,
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          commit: commit.to_gitaly_commit,
          branch_name: encode_binary(branch_name),
          message: encode_binary(message),
          start_branch_name: encode_binary(start_branch_name.to_s),
          start_repository: start_repository.gitaly_repository,
          commit_author_name: encode_binary(author_name),
          commit_author_email: encode_binary(author_email),
          dry_run: dry_run,
          timestamp: Google::Protobuf::Timestamp.new(seconds: Time.now.utc.to_i),
          expected_old_oid: target_sha
        )

        response = gitaly_client_call(
          @repository.storage,
          :operation_service,
          :user_cherry_pick,
          request,
          remote_storage: start_repository.storage,
          timeout: GitalyClient.long_timeout
        )

        Gitlab::Git::OperationService::BranchUpdate.from_gitaly(response.branch_update)
      rescue GRPC::InvalidArgument => ex
        raise Gitlab::Git::CommandError, ex
      rescue GRPC::BadStatus => e
        detailed_error = GitalyClient.decode_detailed_error(e)

        case detailed_error.try(:error)
        when :access_check
          access_check_error = detailed_error.access_check
          # These messages were returned from internal/allowed API calls
          raise Gitlab::Git::PreReceiveError.new(fallback_message: access_check_error.error_message)
        when :cherry_pick_conflict
          raise Gitlab::Git::Repository::CreateTreeError, 'CONFLICT'
        when :changes_already_applied
          raise Gitlab::Git::Repository::CreateTreeError, 'EMPTY'
        when :target_branch_diverged
          raise Gitlab::Git::CommitError, 'branch diverged'
        else
          raise e
        end
      end
      # rubocop:enable Metrics/ParameterLists

      def user_revert(user:, commit:, branch_name:, message:, start_branch_name:, start_repository:, dry_run: false)
        request = Gitaly::UserRevertRequest.new(
          repository: @gitaly_repo,
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          commit: commit.to_gitaly_commit,
          branch_name: encode_binary(branch_name),
          message: encode_binary(message),
          start_branch_name: encode_binary(start_branch_name.to_s),
          start_repository: start_repository.gitaly_repository,
          dry_run: dry_run,
          timestamp: Google::Protobuf::Timestamp.new(seconds: Time.now.utc.to_i)
        )

        response = gitaly_client_call(
          @repository.storage,
          :operation_service,
          :user_revert,
          request,
          remote_storage: start_repository.storage,
          timeout: GitalyClient.long_timeout
        )

        if response.pre_receive_error.presence
          raise Gitlab::Git::PreReceiveError, response.pre_receive_error
        elsif response.commit_error.presence
          raise Gitlab::Git::CommitError, response.commit_error
        elsif response.create_tree_error.presence
          raise Gitlab::Git::Repository::CreateTreeError, response.create_tree_error_code
        end

        Gitlab::Git::OperationService::BranchUpdate.from_gitaly(response.branch_update)

      rescue GRPC::BadStatus => e
        detailed_error = GitalyClient.decode_detailed_error(e)

        case detailed_error.try(:error)
        when :merge_conflict
          raise Gitlab::Git::Repository::CreateTreeError, 'CONFLICT'
        when :changes_already_applied
          raise Gitlab::Git::Repository::CreateTreeError, 'EMPTY'
        when :custom_hook
          raise Gitlab::Git::PreReceiveError.new(custom_hook_error_message(detailed_error.custom_hook),
            fallback_message: CUSTOM_HOOK_FALLBACK_MESSAGE)
        when :not_ancestor
          raise Gitlab::Git::CommitError, 'branch diverged'
        else
          raise e
        end
      end

      def rebase(user, rebase_id, branch:, branch_sha:, remote_repository:, remote_branch:, push_options: [])
        request_enum = QueueEnumerator.new
        response_enum = gitaly_client_call(
          @repository.storage,
          :operation_service,
          :user_rebase_confirmable,
          request_enum.each,
          timeout: GitalyClient.long_timeout,
          remote_storage: remote_repository.storage
        )

        # First request
        request_enum.push(
          Gitaly::UserRebaseConfirmableRequest.new(
            header: Gitaly::UserRebaseConfirmableRequest::Header.new(
              repository: @gitaly_repo,
              user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
              rebase_id: rebase_id.to_s,
              branch: encode_binary(branch),
              branch_sha: branch_sha,
              remote_repository: remote_repository.gitaly_repository,
              remote_branch: encode_binary(remote_branch),
              git_push_options: push_options,
              timestamp: Google::Protobuf::Timestamp.new(seconds: Time.now.utc.to_i)
            )
          )
        )

        response = response_enum.next
        rebase_sha = response.rebase_sha

        yield rebase_sha

        # Second request confirms with gitaly to finalize the rebase
        request_enum.push(Gitaly::UserRebaseConfirmableRequest.new(apply: true))
        request_enum.close
        response_enum.next

        consume_final_message(response_enum)

        rebase_sha
      rescue GRPC::BadStatus => e
        detailed_error = GitalyClient.decode_detailed_error(e)

        case detailed_error.try(:error)
        when :access_check
          access_check_error = detailed_error.access_check
          # These messages were returned from internal/allowed API calls
          raise Gitlab::Git::PreReceiveError.new(fallback_message: access_check_error.error_message)
        when :rebase_conflict
          raise Gitlab::Git::Repository::GitError, e.details
        else
          raise e
        end
      ensure
        request_enum.close
      end

      def user_rebase_to_ref(user, source_sha:, target_ref:, first_parent_ref:, expected_old_oid: "")
        request = Gitaly::UserRebaseToRefRequest.new(
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          repository: @gitaly_repo,
          source_sha: source_sha,
          target_ref: encode_binary(target_ref),
          first_parent_ref: encode_binary(first_parent_ref),
          expected_old_oid: expected_old_oid,
          timestamp: Google::Protobuf::Timestamp.new(seconds: Time.now.utc.to_i)
        )

        response = gitaly_client_call(@repository.storage, :operation_service,
          :user_rebase_to_ref, request, timeout: GitalyClient.long_timeout)

        response.commit_id
      end

      def user_squash(user, start_sha, end_sha, author, message, time = Time.now.utc)
        request = Gitaly::UserSquashRequest.new(
          repository: @gitaly_repo,
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          start_sha: start_sha,
          end_sha: end_sha,
          author: Gitlab::Git::User.from_gitlab(author).to_gitaly,
          commit_message: encode_binary(message),
          timestamp: Google::Protobuf::Timestamp.new(seconds: time.to_i)
        )

        response = gitaly_client_call(
          @repository.storage,
          :operation_service,
          :user_squash,
          request,
          timeout: GitalyClient.long_timeout
        )

        response.squash_sha
      rescue GRPC::BadStatus => e
        detailed_error = GitalyClient.decode_detailed_error(e)

        case detailed_error.try(:error)
        when :resolve_revision, :rebase_conflict
          # Theoretically, we could now raise specific errors based on the type
          # of the detailed error. Most importantly, we get error details when
          # Gitaly was not able to resolve the `start_sha` or `end_sha` via a
          # ResolveRevisionError, and we get information about which files are
          # conflicting via a MergeConflictError.
          #
          # We don't do this now though such that we can maintain backwards
          # compatibility with the minimum required set of changes during the
          # transitory period where we're migrating UserSquash to use
          # structured errors. We thus continue to just return a GitError, like
          # we previously did.
          raise Gitlab::Git::Repository::GitError, e.details
        else
          raise
        end
      end

      def user_update_submodule(user:, submodule:, commit_sha:, branch:, message:)
        request = Gitaly::UserUpdateSubmoduleRequest.new(
          repository: @gitaly_repo,
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          commit_sha: commit_sha,
          branch: encode_binary(branch),
          submodule: encode_binary(submodule),
          commit_message: encode_binary(message),
          timestamp: Google::Protobuf::Timestamp.new(seconds: Time.now.utc.to_i)
        )

        response = gitaly_client_call(
          @repository.storage,
          :operation_service,
          :user_update_submodule,
          request,
          timeout: GitalyClient.long_timeout
        )

        if response.pre_receive_error.present?
          raise Gitlab::Git::PreReceiveError, response.pre_receive_error
        elsif response.commit_error.present?
          raise Gitlab::Git::CommitError, response.commit_error
        else
          Gitlab::Git::OperationService::BranchUpdate.from_gitaly(response.branch_update)
        end
      end

      # rubocop:disable Metrics/ParameterLists
      def user_commit_files(
        user, branch_name, commit_message, actions, author_email, author_name, start_branch_name,
        start_repository, force = false, start_sha = nil, sign = true, target_sha = nil)
        req_enum = Enumerator.new do |y|
          header = user_commit_files_request_header(user, branch_name,
            commit_message, actions, author_email, author_name, start_branch_name,
            start_repository, force, start_sha, sign, target_sha)

          y.yield Gitaly::UserCommitFilesRequest.new(header: header)

          actions.each do |action|
            action_header = user_commit_files_action_header(action)
            y.yield Gitaly::UserCommitFilesRequest.new(
              action: Gitaly::UserCommitFilesAction.new(header: action_header)
            )

            reader = binary_io(action[:content])

            until reader.eof?
              chunk = reader.read(MAX_MSG_SIZE)

              y.yield Gitaly::UserCommitFilesRequest.new(
                action: Gitaly::UserCommitFilesAction.new(content: chunk)
              )
            end
          end
        end

        response = gitaly_client_call(
          @repository.storage, :operation_service, :user_commit_files, req_enum,
          timeout: GitalyClient.long_timeout, remote_storage: start_repository&.storage)

        if (pre_receive_error = response.pre_receive_error.presence)
          raise Gitlab::Git::PreReceiveError, pre_receive_error
        end

        if (index_error = response.index_error.presence)
          raise Gitlab::Git::Index::IndexError, index_error
        end

        Gitlab::Git::OperationService::BranchUpdate.from_gitaly(response.branch_update)
      rescue GRPC::BadStatus => e
        detailed_error = GitalyClient.decode_detailed_error(e)

        case detailed_error.try(:error)
        when :access_check
          access_check_error = detailed_error.access_check
          # These messages were returned from internal/allowed API calls
          raise Gitlab::Git::PreReceiveError.new(fallback_message: access_check_error.error_message)
        when :custom_hook
          raise Gitlab::Git::PreReceiveError.new(custom_hook_error_message(detailed_error.custom_hook),
            fallback_message: CUSTOM_HOOK_FALLBACK_MESSAGE)
        when :index_update
          raise Gitlab::Git::Index::IndexError, index_error_message(detailed_error.index_update)
        else
          handle_undetailed_bad_status_errors(e)

          raise e
        end
      end

      # rubocop:enable Metrics/ParameterLists
      def user_commit_patches(user, branch_name:, patches:, target_sha: nil)
        header = Gitaly::UserApplyPatchRequest::Header.new(
          repository: @gitaly_repo,
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          target_branch: encode_binary(branch_name),
          timestamp: Google::Protobuf::Timestamp.new(seconds: Time.now.utc.to_i),
          expected_old_oid: target_sha
        )
        reader = binary_io(patches)

        chunks = Enumerator.new do |chunk|
          chunk.yield Gitaly::UserApplyPatchRequest.new(header: header)

          until reader.eof?
            patch_chunk = reader.read(MAX_MSG_SIZE)

            chunk.yield(Gitaly::UserApplyPatchRequest.new(patches: patch_chunk))
          end
        end

        response = gitaly_client_call(@repository.storage, :operation_service,
          :user_apply_patch, chunks, timeout: GitalyClient.long_timeout)

        Gitlab::Git::OperationService::BranchUpdate.from_gitaly(response.branch_update)
      end

      private

      # consume_final_message consumes the final message that contains the status from the response
      # stream and raises an exception if it wasn't the last one.
      def consume_final_message(response_enum)
        response_enum.next
      rescue StopIteration
      else
        raise 'expected response stream to finish'
      end

      # rubocop:disable Metrics/ParameterLists
      def user_commit_files_request_header(
        user, branch_name, commit_message, actions, author_email, author_name,
        start_branch_name, start_repository, force, start_sha, sign, target_sha)

        Gitaly::UserCommitFilesRequestHeader.new(
          repository: @gitaly_repo,
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          branch_name: encode_binary(branch_name),
          commit_message: encode_binary(commit_message),
          commit_author_name: encode_binary(author_name),
          commit_author_email: encode_binary(author_email),
          start_branch_name: encode_binary(start_branch_name),
          start_repository: start_repository&.gitaly_repository,
          force: force,
          start_sha: encode_binary(start_sha),
          sign: sign,
          expected_old_oid: target_sha,
          timestamp: Google::Protobuf::Timestamp.new(seconds: Time.now.utc.to_i)
        )
      end
      # rubocop:enable Metrics/ParameterLists

      def user_commit_files_action_header(action)
        Gitaly::UserCommitFilesActionHeader.new(
          action: action[:action].upcase.to_sym,
          file_path: encode_binary(action[:file_path]),
          previous_path: encode_binary(action[:previous_path]),
          base64_content: action[:encoding] == 'base64',
          execute_filemode: !!action[:execute_filemode],
          infer_content: !!action[:infer_content]
        )
      rescue RangeError
        raise ArgumentError, "Unknown action '#{action[:action]}'"
      end

      def custom_hook_error_message(custom_hook_error)
        # Custom hooks may return messages via either stdout or stderr which have a specific prefix. If
        # that prefix is present we'll want to print the hook's output.
        custom_hook_output = custom_hook_error.stderr.presence || custom_hook_error.stdout
        EncodingHelper.encode!(custom_hook_output)
      end

      def index_error_message(index_error)
        encoded_path = EncodingHelper.encode!(index_error.path)

        case index_error.error_type
        when :ERROR_TYPE_EMPTY_PATH
          "You must provide a file path"
        when :ERROR_TYPE_INVALID_PATH
          "invalid path: '#{encoded_path}'"
        when :ERROR_TYPE_DIRECTORY_EXISTS
          "A directory with this name already exists"
        when :ERROR_TYPE_DIRECTORY_TRAVERSAL
          "Path cannot include directory traversal"
        when :ERROR_TYPE_FILE_EXISTS
          "A file with this name already exists"
        when :ERROR_TYPE_FILE_NOT_FOUND
          "A file with this name doesn't exist"
        else
          "Unknown error performing git operation"
        end
      end

      def handle_undetailed_bad_status_errors(error)
        # Some invalid path errors are caught by Gitaly directly and returned
        # as an :index_update error, while others are found by libgit2 and
        # come as generic errors. We need to convert the latter as IndexErrors
        # as well.
        if error.to_status.details.start_with?('invalid path')
          raise Gitlab::Git::Index::IndexError, error.to_status.details
        elsif error.is_a?(GRPC::InvalidArgument) && error.to_status.details.include?('expected old object ID')
          raise Gitlab::Git::CommandError, error
        end
      end
    end
  end
end
