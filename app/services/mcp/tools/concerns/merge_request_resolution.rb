# frozen_string_literal: true

module Mcp
  module Tools
    module Concerns
      # Shared url-or-ids merge request lookup. Host must provide `current_user`
      # and include ResourceFinder (for find_project!).
      module MergeRequestResolution
        private

        def resolve_merge_request!(args)
          if args[:url].present?
            match = ::MergeRequest.link_reference_pattern.match(args[:url])
            raise ArgumentError, "Invalid merge request URL: #{args[:url]}" unless match

            project = find_project!("#{match[:namespace]}/#{match[:project]}")
            iid = match[:merge_request].to_i
          else
            iid = args[:merge_request_iid]
            unless iid && args[:project_id].present?
              raise ArgumentError, 'Provide either url, or project_id and merge_request_iid'
            end

            project = find_project!(args[:project_id])
          end

          merge_request = ::MergeRequestsFinder.new(
            current_user,
            project_id: project.id,
            iids: [iid]
          ).execute.first

          raise ArgumentError, 'Merge request not found or you do not have access to it.' unless merge_request

          merge_request
        end
      end
    end
  end
end
