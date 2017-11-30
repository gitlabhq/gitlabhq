module Gitlab
  module GitalyClient
    class OperationService
      def initialize(repository)
        @gitaly_repo = repository.gitaly_repository
        @repository = repository
      end

      def rm_tag(tag_name, user)
        request = Gitaly::UserDeleteTagRequest.new(
          repository: @gitaly_repo,
          tag_name: GitalyClient.encode(tag_name),
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
          tag_name: GitalyClient.encode(tag_name),
          target_revision: GitalyClient.encode(target),
          message: GitalyClient.encode(message.to_s)
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
          branch_name: GitalyClient.encode(branch_name),
          user: Gitlab::Git::User.from_gitlab(user).to_gitaly,
          start_point: GitalyClient.encode(start_point)
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
          branch_name: GitalyClient.encode(branch_name),
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
            branch: GitalyClient.encode(target_branch),
            message: GitalyClient.encode(message)
          )
        )

        yield response_enum.next.commit_id

        request_enum.push(Gitaly::UserMergeBranchRequest.new(apply: true))

        branch_update = response_enum.next.branch_update
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
          branch: GitalyClient.encode(target_branch)
        )

        branch_update = GitalyClient.call(
          @repository.storage,
          :operation_service,
          :user_ff_branch,
          request
        ).branch_update
        Gitlab::Git::OperationService::BranchUpdate.from_gitaly(branch_update)
      end
    end
  end
end
