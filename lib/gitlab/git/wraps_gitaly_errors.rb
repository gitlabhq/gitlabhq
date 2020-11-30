# frozen_string_literal: true

module Gitlab
  module Git
    module WrapsGitalyErrors
      def wrapped_gitaly_errors(&block)
        yield block
      rescue GRPC::NotFound => e
        raise Gitlab::Git::Repository::NoRepository.new(e)
      rescue GRPC::InvalidArgument => e
        raise ArgumentError.new(e)
      rescue GRPC::DeadlineExceeded => e
        raise Gitlab::Git::CommandTimedOut.new(e)
      rescue GRPC::BadStatus => e
        raise Gitlab::Git::CommandError.new(e)
      end
    end
  end
end
