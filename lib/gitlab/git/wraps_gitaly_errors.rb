# frozen_string_literal: true

module Gitlab
  module Git
    module WrapsGitalyErrors
      def wrapped_gitaly_errors(&block)
        yield block
      rescue GRPC::BadStatus => e
        # The GRPC::BadStatus is the fundamental error that serves as the basis for all other gRPC error categories,
        # including GRPC::InvalidArgument. It is essential to note that rescuing the specific exception class does not
        # account for all possible cases. In this regard, a status exception can be directly generated from
        # GRPC::BadStatus. Therefore, it is recommended that we capture and rescue the GRPC::BadStatus and assert the
        # status code to ensure adequate coverage of error cases.
        case e.code
        when GRPC::Core::StatusCodes::NOT_FOUND
          handle_not_found(e)
        when GRPC::Core::StatusCodes::INVALID_ARGUMENT
          raise ArgumentError, e
        when GRPC::Core::StatusCodes::DEADLINE_EXCEEDED
          raise Gitlab::Git::CommandTimedOut, e
        when GRPC::Core::StatusCodes::RESOURCE_EXHAUSTED
          handle_resource_exhausted(e)
        else
          raise Gitlab::Git::CommandError, e
        end
      end

      private

      def handle_resource_exhausted(exception)
        detail = Gitlab::GitalyClient.decode_detailed_error(exception)

        case detail.class.name
        when Gitaly::LimitError.name
          retry_after = detail&.retry_after&.seconds
          raise ResourceExhaustedError.new(
            "Upstream Gitaly has been exhausted: #{detail.error_message}. Try again later", retry_after
          )
        else
          raise ResourceExhaustedError, _("Upstream Gitaly has been exhausted. Try again later")
        end
      end

      def handle_not_found(exception)
        detail = Gitlab::GitalyClient.decode_detailed_error(exception)

        case detail.class.name
        when Gitaly::ReferenceNotFoundError.name
          raise Gitlab::Git::ReferenceNotFoundError.new(
            exception, detail.reference_name
          )
        when Gitaly::FindCommitsError.name
          raise Gitlab::Git::Repository::CommitNotFound, exception
        else
          raise Gitlab::Git::Repository::NoRepository, exception
        end
      end
    end
  end
end
