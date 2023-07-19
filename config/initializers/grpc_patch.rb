# frozen_string_literal: true

require 'grpc'

# grpc v1.42 and up introduced a regression where a non-standard
# exception, `GRPC::Core::CallError`, is raised instead of
# DeadlineExceeded: https://github.com/grpc/grpc/issues/33283.
# This patch applies https://github.com/grpc/grpc/pull/33565.
module Gitlab
  module GRPCPatch
    module ActiveCall
      def remote_read
        super
      ensure
        # Ensure we don't attempt to request the initial metadata again
        # in case an exception occurs.
        @metadata_received = true # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end

      def receive_and_check_status
        super
      ensure
        # Ensure we don't attempt to request the initial metadata again
        # in case an exception occurs.
        @metadata_received = true # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end
    end
  end
end

GRPC::ActiveCall.prepend Gitlab::GRPCPatch::ActiveCall
