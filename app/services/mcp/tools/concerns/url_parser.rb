# frozen_string_literal: true

module Mcp
  module Tools
    module Concerns
      module UrlParser
        extend ActiveSupport::Concern
        include Constants

        private

        def resolve_parent_from_url(url)
          parsed = parse_parent_url(url)
          parent = find_parent_by_id_or_path(parsed[:type], parsed[:path])

          raise ArgumentError, "#{parsed[:type].to_s.capitalize} not found: '#{parsed[:path]}'" unless parent

          { type: parsed[:type], full_path: parent.full_path, record: parent }
        end

        def resolve_work_item_from_url(url)
          parsed = parse_work_item_url(url)
          parent = find_parent_by_id_or_path(parsed[:parent_type], parsed[:parent_path])

          unless parent
            raise ArgumentError, "#{parsed[:parent_type].to_s.capitalize} not found: '#{parsed[:parent_path]}'"
          end

          work_item = find_work_item_in_parent(parent, parsed[:work_item_iid])

          work_item.to_global_id.to_s
        end

        # Parse parent URL (group or project)
        # Examples:
        #   https://gitlab.com/namespace/project -> { type: :project, path: 'namespace/project' }
        #   https://gitlab.com/groups/namespace/group -> { type: :group, path: 'namespace/group' }
        #   https://gitlab.com/namespace/project/-/merge_requests -> { type: :project, path: 'namespace/project' }
        def parse_parent_url(url)
          path = extract_path_from_url(url)
          path = path.split('/-/').first || path

          if path.start_with?('groups/')
            { type: :group, path: path.delete_prefix('groups/') }
          else
            { type: :project, path: path }
          end
        end

        # Parse work item URL
        # Examples:
        #   https://gitlab.com/namespace/project/-/work_items/42
        #   https://gitlab.com/groups/namespace/group/-/work_items/42
        def parse_work_item_url(url)
          path = extract_path_from_url(url)
          match = path.match(self.class::URL_PATTERNS[:work_item])

          raise ArgumentError, "Invalid work item URL format. Expected: .../-/work_items/<iid>" unless match

          parent_path = match[:path]
          parent_type = path.start_with?('groups/') ? :group : :project

          { parent_type: parent_type, parent_path: parent_path, work_item_iid: match[:id].to_i }
        end

        def extract_path_from_url(url)
          raise ArgumentError, "Invalid URL format: #{url}" unless valid_url?(url)

          URI.parse(url).path.delete_prefix('/')
        end

        def valid_url?(url)
          uri = URI.parse(url)
          %w[http https].include?(uri.scheme)
        rescue URI::BadURIError, URI::InvalidURIError => e
          raise ArgumentError, "Invalid URL format: #{e.message}"
        end
      end
    end
  end
end
