module Gitlab
  module GitalyClient
    class DiffStitcher
      include Enumerable

      def initialize(rpc_response)
        @rpc_response = rpc_response
      end

      def each
        current_diff = nil

        @rpc_response.each do |diff_msg|
          if current_diff.nil?
            diff_params = diff_msg.to_h.slice(*GitalyClient::Diff::FIELDS)
            diff_params[:patch] = diff_msg.raw_patch_data

            current_diff = GitalyClient::Diff.new(diff_params)
          else
            current_diff.patch += diff_msg.raw_patch_data
          end

          if diff_msg.end_of_patch
            yield current_diff
            current_diff = nil
          end
        end
      end
    end
  end
end
