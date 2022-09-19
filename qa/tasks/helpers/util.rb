# frozen_string_literal: true

module Task
  module Helpers
    module Util
      include ::QA::Support::API

      # Append text to file
      #
      # @param [String] path
      # @param [String] text
      # @return [void]
      def append_to_file(path, text)
        File.open(path, "a") { |f| f.write(text) }
      end

      # Merge request labels
      #
      # @return [Array]
      def mr_labels
        ENV["CI_MERGE_REQUEST_LABELS"]&.split(',') || []
      end

      # Merge request changes
      #
      # @return [Array<Hash>]
      def mr_diff
        mr_iid = ENV["CI_MERGE_REQUEST_IID"]
        return [] unless mr_iid

        gitlab_endpoint = ENV["CI_API_V4_URL"]
        gitlab_token = ENV["PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE"]
        project_id = ENV["CI_MERGE_REQUEST_PROJECT_ID"]

        response = get(
          "#{gitlab_endpoint}/projects/#{project_id}/merge_requests/#{mr_iid}/changes",
          headers: { "PRIVATE-TOKEN" => gitlab_token }
        )

        parse_body(response).fetch(:changes, []).map do |change|
          {
            path: change[:new_path],
            **change.slice(:new_file, :deleted_file, :diff)
          }
        end
      end
    end
  end
end
