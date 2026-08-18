# frozen_string_literal: true

module Gitlab
  module Git
    module WrapsGitalyErrors
      # Phrase present in gRPC's message when a response exceeds the 4 MiB
      # max-message-size cap (gitlab-org/gitlab#362327). This is a permanent
      # configuration limit, not a transient load condition, so it must not be
      # reported with "Try again later".
      MESSAGE_SIZE_LIMIT_PHRASE = 'message larger than max'

      def wrapped_gitaly_errors(&block)
        yield block
      rescue GRPC::BadStatus => e
        # The GRPC::BadStatus is the fundamental error that serves as the basis for all other gRPC error categories,
        # including GRPC::InvalidArgument. It is essential to note that rescuing the specific exception class does not
        # account for all possible cases. In this regard, a status exception can be directly generated from
        # GRPC::BadStatus. Therefore, it is recommended that we capture and rescue the GRPC::BadStatus and assert the
        # status code to ensure adequate coverage of error cases.
        handle_error(e)
      end

      private

      # handle_error first tries to handle the error as a detailed error, if no mapping found,
      # it falls back to handling it as a default error according to the error code.
      def handle_error(exception)
        error = Gitlab::GitalyClient.unwrap_detailed_error(exception)
        handle_detailed_error(error, exception) || handle_default_error(exception)
      end

      def handle_detailed_error(error, exception)
        case error
        when Gitaly::ReferenceNotFoundError
          raise Gitlab::Git::ReferenceNotFoundError.new(exception, error.reference_name)
        when Gitaly::FindCommitsError
          raise Gitlab::Git::Repository::CommitNotFound, exception
        when Gitaly::AmbiguousReferenceError
          raise Gitlab::Git::AmbiguousRef, exception
        when Gitaly::LimitError
          raise ResourceExhaustedError.new(
            "Upstream Gitaly has been exhausted: #{error.error_message}. Try again later", error.retry_after&.seconds
          )
        end
      end

      def handle_default_error(exception)
        case exception.code
        when GRPC::Core::StatusCodes::NOT_FOUND
          raise Gitlab::Git::Repository::NoRepository, exception
        when GRPC::Core::StatusCodes::INVALID_ARGUMENT
          raise ArgumentError, exception
        when GRPC::Core::StatusCodes::DEADLINE_EXCEEDED
          raise Gitlab::Git::CommandTimedOut, exception
        when GRPC::Core::StatusCodes::RESOURCE_EXHAUSTED
          raise_resource_exhausted_error(exception)
        else
          raise Gitlab::Git::CommandError, exception
        end
      end

      def raise_resource_exhausted_error(exception)
        unless exception.message.to_s.downcase.include?(MESSAGE_SIZE_LIMIT_PHRASE)
          raise ResourceExhaustedError, _("Upstream Gitaly has been exhausted. Try again later")
        end

        raise ResourceExhaustedError,
          _("The response from Gitaly is too large to load. " \
            "Maybe, the repository or merge request contains too many commits. " \
            "This is a size limit, not a temporary error.")
      end
    end
  end
end
