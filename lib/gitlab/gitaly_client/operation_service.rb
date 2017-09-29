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
          user: Util.gitaly_user(user)
        )

        response = GitalyClient.call(@repository.storage, :operation_service, :user_delete_tag, request)

        if pre_receive_error = response.pre_receive_error.presence
          raise Gitlab::Git::HooksService::PreReceiveError, pre_receive_error
        end
      end

      def add_tag(tag_name, user, target, message)
        request = Gitaly::UserCreateTagRequest.new(
          repository: @gitaly_repo,
          user: Util.gitaly_user(user),
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
    end
  end
end
