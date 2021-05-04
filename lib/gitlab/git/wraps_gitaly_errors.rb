# frozen_string_literal: true

module Gitlab
  module Git
    module WrapsGitalyErrors
      def wrapped_gitaly_errors(&block)
        yield block
      rescue GRPC::NotFound => e
        raise Gitlab::Git::Repository::NoRepository, e
      rescue GRPC::InvalidArgument => e
        raise ArgumentError, e
      rescue GRPC::DeadlineExceeded => e
        raise Gitlab::Git::CommandTimedOut, e
      rescue GRPC::BadStatus => e
        raise Gitlab::Git::CommandError, e
      end
    end
  end
end
