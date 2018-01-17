module Gitlab
  module GitalyClient
    class OperationService
      include Gitlab::EncodingHelper

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

        response = GitalyClient.call(@repository.storage, :operation_service, :user_delete_tag, request)

        if pre_receive_error = response.pre_receive_error.presence
          raise Gitlab::Git::HooksService::PreReceiveError, pre_receive_error
        end
      end

      def add_tag(tag_name, user, target, message)
        request = Gitaly::UserCreateTagRequest.new(
          repository: @gitaly_repo,
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          tag_name: encode_binary(tag_name),
          target_revision: encode_binary(target),
          message: encode_binary(message.to_s)
        )

        response = GitalyClient.call(@repository.storage, :operation_service, :user_create_tag, request)
        if pre_receive_error = response.pre_receive_error.presence
          raise Gitlab::Git::HooksService::PreReceiveError, pre_receive_error
        elsif response.exists
          raise Gitlab::Git::Repository::TagExistsError
        end

        Util.gitlab_tag_from_gitaly_tag(@repository, response.tag)
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
          :user_create_branch, request)

        if response.pre_receive_error.present?
          raise Gitlab::Git::HooksService::PreReceiveError.new(response.pre_receive_error)
        end

        branch = response.branch
        return nil unless branch

        target_commit = Gitlab::Git::Commit.decorate(@repository, branch.target_commit)
        Gitlab::Git::Branch.new(@repository, branch.name, target_commit.id, target_commit)
      end

      def user_delete_branch(branch_name, user)
        request = Gitaly::UserDeleteBranchRequest.new(
          repository: @gitaly_repo,
          branch_name: encode_binary(branch_name),
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly
        )

        response = GitalyClient.call(@repository.storage, :operation_service, :user_delete_branch, request)

        if pre_receive_error = response.pre_receive_error.presence
          raise Gitlab::Git::HooksService::PreReceiveError, pre_receive_error
        end
      end

      def user_merge_branch(user, source_sha, target_branch, message)
        request_enum = QueueEnumerator.new
        response_enum = GitalyClient.call(
          @repository.storage,
          :operation_service,
          :user_merge_branch,
          request_enum.each
        )

        request_enum.push(
          Gitaly::UserMergeBranchRequest.new(
            repository: @gitaly_repo,
            user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
            commit_id: source_sha,
            branch: encode_binary(target_branch),
            message: encode_binary(message)
          )
        )

        yield response_enum.next.commit_id

        request_enum.push(Gitaly::UserMergeBranchRequest.new(apply: true))

        branch_update = response_enum.next.branch_update
        return if branch_update.nil?
        raise Gitlab::Git::CommitError.new('failed to apply merge to branch') unless branch_update.commit_id.present?

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

        branch_update = GitalyClient.call(
          @repository.storage,
          :operation_service,
          :user_ff_branch,
          request
        ).branch_update
        Gitlab::Git::OperationService::BranchUpdate.from_gitaly(branch_update)
      end

      def user_cherry_pick(user:, commit:, branch_name:, message:, start_branch_name:, start_repository:)
        call_cherry_pick_or_revert(:cherry_pick,
                                   user: user,
                                   commit: commit,
                                   branch_name: branch_name,
                                   message: message,
                                   start_branch_name: start_branch_name,
                                   start_repository: start_repository)
      end

      def user_revert(user:, commit:, branch_name:, message:, start_branch_name:, start_repository:)
        call_cherry_pick_or_revert(:revert,
                                   user: user,
                                   commit: commit,
                                   branch_name: branch_name,
                                   message: message,
                                   start_branch_name: start_branch_name,
                                   start_repository: start_repository)
      end

      def user_rebase(user, rebase_id, branch:, branch_sha:, remote_repository:, remote_branch:)
        request = Gitaly::UserRebaseRequest.new(
          repository: @gitaly_repo,
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          rebase_id: rebase_id.to_s,
          branch: encode_binary(branch),
          branch_sha: branch_sha,
          remote_repository: remote_repository.gitaly_repository,
          remote_branch: encode_binary(remote_branch)
        )

        response = GitalyClient.call(
          @repository.storage,
          :operation_service,
          :user_rebase,
          request,
          remote_storage: remote_repository.storage
        )

        if response.pre_receive_error.presence
          raise Gitlab::Git::HooksService::PreReceiveError, response.pre_receive_error
        elsif response.git_error.presence
          raise Gitlab::Git::Repository::GitError, response.git_error
        else
          response.rebase_sha
        end
      end

      private

      def call_cherry_pick_or_revert(rpc, user:, commit:, branch_name:, message:, start_branch_name:, start_repository:)
        request_class = "Gitaly::User#{rpc.to_s.camelcase}Request".constantize

        request = request_class.new(
          repository: @gitaly_repo,
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          commit: commit.to_gitaly_commit,
          branch_name: encode_binary(branch_name),
          message: encode_binary(message),
          start_branch_name: encode_binary(start_branch_name.to_s),
          start_repository: start_repository.gitaly_repository
        )

        response = GitalyClient.call(
          @repository.storage,
          :operation_service,
          :"user_#{rpc}",
          request,
          remote_storage: start_repository.storage
        )

        handle_cherry_pick_or_revert_response(response)
      end

      def handle_cherry_pick_or_revert_response(response)
        if response.pre_receive_error.presence
          raise Gitlab::Git::HooksService::PreReceiveError, response.pre_receive_error
        elsif response.commit_error.presence
          raise Gitlab::Git::CommitError, response.commit_error
        elsif response.create_tree_error.presence
          raise Gitlab::Git::Repository::CreateTreeError, response.create_tree_error
        else
          Gitlab::Git::OperationService::BranchUpdate.from_gitaly(response.branch_update)
        end
      end
    end
  end
end
