# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class DiffStitcher
      include Enumerable

      delegate :size, to: :rpc_response

      def initialize(rpc_response_param)
        @rpc_response = rpc_response_param
      end

      def each
        current_diff = nil

        @rpc_response.each do |diff_msg|
          if current_diff.nil?
            diff_params = diff_msg.to_h.slice(*GitalyClient::Diff::ATTRS)
            # gRPC uses frozen strings by default, and we need to have an unfrozen string as it
            # gets processed further down the line. So we unfreeze the first chunk of the patch
            # in case it's the only chunk we receive for this diff.
            diff_params[:patch] = diff_msg.raw_patch_data.dup

            current_diff = GitalyClient::Diff.new(diff_params)
          else
            current_diff.patch = "#{current_diff.patch}#{diff_msg.raw_patch_data}"
          end

          if diff_msg.end_of_patch
            yield current_diff
            current_diff = nil
          end
        end
      end

      private

      attr_reader :rpc_response
    end
  end
end
