# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class OperationService
      include Gitlab::EncodingHelper

      MAX_MSG_SIZE = 128.kilobytes.freeze

      def initialize(repository)
        @gitaly_repo = repository.gitaly_repository
        @repository = repository
      end

      def rm_tag(tag_name, user)
        request = Gitaly::UserDeleteTagRequest.new(
          repository: @gitaly_repo,
          tag_name: encode_binary(tag_name),
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly
        )

        response = GitalyClient.call(@repository.storage, :operation_service, :user_delete_tag, request, timeout: GitalyClient.long_timeout)

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

        response = GitalyClient.call(@repository.storage, :operation_service, :user_create_tag, request, timeout: GitalyClient.long_timeout)
        if pre_receive_error = response.pre_receive_error.presence
          raise Gitlab::Git::PreReceiveError, pre_receive_error
        elsif response.exists
          raise Gitlab::Git::Repository::TagExistsError
        end

        Gitlab::Git::Tag.new(@repository, response.tag)
      rescue GRPC::FailedPrecondition => e
        raise Gitlab::Git::Repository::InvalidRef, e
      end

      def user_create_branch(branch_name, user, start_point)
        request = Gitaly::UserCreateBranchRequest.new(
          repository: @gitaly_repo,
          branch_name: encode_binary(branch_name),
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          start_point: encode_binary(start_point)
        )
        response = GitalyClient.call(@repository.storage, :operation_service,
                                     :user_create_branch, request, timeout: GitalyClient.long_timeout)

        if response.pre_receive_error.present?
          raise Gitlab::Git::PreReceiveError, response.pre_receive_error
        end

        branch = response.branch
        return unless branch

        target_commit = Gitlab::Git::Commit.decorate(@repository, branch.target_commit)
        Gitlab::Git::Branch.new(@repository, branch.name, target_commit.id, target_commit)
      rescue GRPC::FailedPrecondition => ex
        raise Gitlab::Git::Repository::InvalidRef, ex
      end

      def user_update_branch(branch_name, user, newrev, oldrev)
        request = Gitaly::UserUpdateBranchRequest.new(
          repository: @gitaly_repo,
          branch_name: encode_binary(branch_name),
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          newrev: encode_binary(newrev),
          oldrev: encode_binary(oldrev)
        )

        response = GitalyClient.call(@repository.storage, :operation_service,
                                     :user_update_branch, request, timeout: GitalyClient.long_timeout)

        if pre_receive_error = response.pre_receive_error.presence
          raise Gitlab::Git::PreReceiveError, pre_receive_error
        end
      end

      def user_delete_branch(branch_name, user)
        request = Gitaly::UserDeleteBranchRequest.new(
          repository: @gitaly_repo,
          branch_name: encode_binary(branch_name),
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly
        )

        response = GitalyClient.call(@repository.storage, :operation_service,
                                     :user_delete_branch, request, timeout: GitalyClient.long_timeout)

        if pre_receive_error = response.pre_receive_error.presence
          raise Gitlab::Git::PreReceiveError, pre_receive_error
        end
      end

      def user_merge_to_ref(user, source_sha:, branch:, target_ref:, message:, first_parent_ref:, allow_conflicts: false)
        request = Gitaly::UserMergeToRefRequest.new(
          repository: @gitaly_repo,
          source_sha: source_sha,
          branch: encode_binary(branch),
          target_ref: encode_binary(target_ref),
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          message: encode_binary(message),
          first_parent_ref: encode_binary(first_parent_ref),
          allow_conflicts: allow_conflicts,
          timestamp: Google::Protobuf::Timestamp.new(seconds: Time.now.utc.to_i)
        )

        response = GitalyClient.call(@repository.storage, :operation_service,
                                     :user_merge_to_ref, request, timeout: GitalyClient.long_timeout)

        if pre_receive_error = response.pre_receive_error.presence
          raise Gitlab::Git::PreReceiveError, pre_receive_error
        end

        response.commit_id
      end

      def user_merge_branch(user, source_sha, target_branch, message)
        request_enum = QueueEnumerator.new
        response_enum = GitalyClient.call(
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
            message: encode_binary(message),
            timestamp: Google::Protobuf::Timestamp.new(seconds: Time.now.utc.to_i)
          )
        )

        yield response_enum.next.commit_id

        request_enum.push(Gitaly::UserMergeBranchRequest.new(apply: true))

        second_response = response_enum.next

        if second_response.pre_receive_error.present?
          raise Gitlab::Git::PreReceiveError, second_response.pre_receive_error
        end

        branch_update = second_response.branch_update
        return if branch_update.nil?
        raise Gitlab::Git::CommitError, 'failed to apply merge to branch' unless branch_update.commit_id.present?

        Gitlab::Git::OperationService::BranchUpdate.from_gitaly(branch_update)
      ensure
        request_enum.close
      end

      def user_ff_branch(user, source_sha, target_branch)
        request = Gitaly::UserFFBranchRequest.new(
          repository: @gitaly_repo,
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          commit_id: source_sha,
          branch: encode_binary(target_branch)
        )

        response = GitalyClient.call(
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
      rescue GRPC::FailedPrecondition => e
        raise Gitlab::Git::CommitError, e
      end

      def user_cherry_pick(user:, commit:, branch_name:, message:, start_branch_name:, start_repository:, dry_run: false)
        call_cherry_pick_or_revert(:cherry_pick,
                                   user: user,
                                   commit: commit,
                                   branch_name: branch_name,
                                   message: message,
                                   start_branch_name: start_branch_name,
                                   start_repository: start_repository,
                                   dry_run: dry_run)
      end

      def user_revert(user:, commit:, branch_name:, message:, start_branch_name:, start_repository:, dry_run: false)
        call_cherry_pick_or_revert(:revert,
                                   user: user,
                                   commit: commit,
                                   branch_name: branch_name,
                                   message: message,
                                   start_branch_name: start_branch_name,
                                   start_repository: start_repository,
                                   dry_run: dry_run)
      end

      def rebase(user, rebase_id, branch:, branch_sha:, remote_repository:, remote_branch:, push_options: [])
        request_enum = QueueEnumerator.new
        rebase_sha = nil

        response_enum = GitalyClient.call(
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

        perform_next_gitaly_rebase_request(response_enum) do |response|
          rebase_sha = response.rebase_sha
        end

        yield rebase_sha

        # Second request confirms with gitaly to finalize the rebase
        request_enum.push(Gitaly::UserRebaseConfirmableRequest.new(apply: true))

        perform_next_gitaly_rebase_request(response_enum)

        rebase_sha
      ensure
        request_enum.close
      end

      def user_squash(user, squash_id, start_sha, end_sha, author, message, time = Time.now.utc)
        request = Gitaly::UserSquashRequest.new(
          repository: @gitaly_repo,
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          squash_id: squash_id.to_s,
          start_sha: start_sha,
          end_sha: end_sha,
          author: Gitlab::Git::User.from_gitlab(author).to_gitaly,
          commit_message: encode_binary(message),
          timestamp: Google::Protobuf::Timestamp.new(seconds: time.to_i)
        )

        response = GitalyClient.call(
          @repository.storage,
          :operation_service,
          :user_squash,
          request,
          timeout: GitalyClient.long_timeout
        )

        if response.git_error.presence
          raise Gitlab::Git::Repository::GitError, response.git_error
        end

        response.squash_sha
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

        response = GitalyClient.call(
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
        user, branch_name, commit_message, actions, author_email, author_name,
        start_branch_name, start_repository, force = false, start_sha = nil)
        req_enum = Enumerator.new do |y|
          header = user_commit_files_request_header(user, branch_name,
          commit_message, actions, author_email, author_name,
          start_branch_name, start_repository, force, start_sha)

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

        response = GitalyClient.call(@repository.storage, :operation_service,
                                     :user_commit_files, req_enum, timeout: GitalyClient.long_timeout,
                                     remote_storage: start_repository.storage)

        if (pre_receive_error = response.pre_receive_error.presence)
          raise Gitlab::Git::PreReceiveError, pre_receive_error
        end

        if (index_error = response.index_error.presence)
          raise Gitlab::Git::Index::IndexError, index_error
        end

        Gitlab::Git::OperationService::BranchUpdate.from_gitaly(response.branch_update)
      end
      # rubocop:enable Metrics/ParameterLists

      def user_commit_patches(user, branch_name, patches)
        header = Gitaly::UserApplyPatchRequest::Header.new(
          repository: @gitaly_repo,
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          target_branch: encode_binary(branch_name),
          timestamp: Google::Protobuf::Timestamp.new(seconds: Time.now.utc.to_i)
        )
        reader = binary_io(patches)

        chunks = Enumerator.new do |chunk|
          chunk.yield Gitaly::UserApplyPatchRequest.new(header: header)

          until reader.eof?
            patch_chunk = reader.read(MAX_MSG_SIZE)

            chunk.yield(Gitaly::UserApplyPatchRequest.new(patches: patch_chunk))
          end
        end

        response = GitalyClient.call(@repository.storage, :operation_service,
                                     :user_apply_patch, chunks, timeout: GitalyClient.long_timeout)

        Gitlab::Git::OperationService::BranchUpdate.from_gitaly(response.branch_update)
      end

      private

      def perform_next_gitaly_rebase_request(response_enum)
        response = response_enum.next

        if response.pre_receive_error.present?
          raise Gitlab::Git::PreReceiveError, response.pre_receive_error
        elsif response.git_error.present?
          raise Gitlab::Git::Repository::GitError, response.git_error
        end

        yield response if block_given?

        response
      end

      def call_cherry_pick_or_revert(rpc, user:, commit:, branch_name:, message:, start_branch_name:, start_repository:, dry_run:)
        request_class = "Gitaly::User#{rpc.to_s.camelcase}Request".constantize

        request = request_class.new(
          repository: @gitaly_repo,
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          commit: commit.to_gitaly_commit,
          branch_name: encode_binary(branch_name),
          message: encode_binary(message),
          start_branch_name: encode_binary(start_branch_name.to_s),
          start_repository: start_repository.gitaly_repository,
          dry_run: dry_run
        )

        response = GitalyClient.call(
          @repository.storage,
          :operation_service,
          :"user_#{rpc}",
          request,
          remote_storage: start_repository.storage,
          timeout: GitalyClient.long_timeout
        )

        handle_cherry_pick_or_revert_response(response)
      end

      def handle_cherry_pick_or_revert_response(response)
        if response.pre_receive_error.presence
          raise Gitlab::Git::PreReceiveError, response.pre_receive_error
        elsif response.commit_error.presence
          raise Gitlab::Git::CommitError, response.commit_error
        elsif response.create_tree_error.presence
          raise Gitlab::Git::Repository::CreateTreeError, response.create_tree_error_code
        end

        Gitlab::Git::OperationService::BranchUpdate.from_gitaly(response.branch_update)
      end

      # rubocop:disable Metrics/ParameterLists
      def user_commit_files_request_header(
        user, branch_name, commit_message, actions, author_email, author_name,
        start_branch_name, start_repository, force, start_sha)

        Gitaly::UserCommitFilesRequestHeader.new(
          repository: @gitaly_repo,
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          branch_name: encode_binary(branch_name),
          commit_message: encode_binary(commit_message),
          commit_author_name: encode_binary(author_name),
          commit_author_email: encode_binary(author_email),
          start_branch_name: encode_binary(start_branch_name),
          start_repository: start_repository.gitaly_repository,
          force: force,
          start_sha: encode_binary(start_sha),
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
    end
  end
end
