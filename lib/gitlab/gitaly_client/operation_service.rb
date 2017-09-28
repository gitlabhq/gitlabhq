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
    end
  end
end
