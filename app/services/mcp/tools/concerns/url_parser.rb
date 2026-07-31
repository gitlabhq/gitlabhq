# frozen_string_literal: true

module Mcp
  module Tools
    module Concerns
      module UrlParser
        extend ActiveSupport::Concern

        class_methods do
          include Gitlab::Utils::StrongMemoize

          # Anchored and bounded by a path separator, so a project like
          # `/gitlab-org/project` is not mangled by a `/gitlab` root.
          def relative_url_root_regex
            root = Gitlab.config.gitlab.relative_url_root
            return if root.blank?

            %r{\A/?#{Regexp.escape(root)}(?=/|\z)}
          end
          strong_memoize_attr :relative_url_root_regex
        end

        WORK_ITEM_URL_PATTERN = %r{\A/?(?:groups/)?(?<path>\S*)/-/work_items/(?<id>\d+)\z}

        private

        def resolve_parent_from_url(url)
          parsed = parse_parent_url(url)
          parent = find_parent_by_id_or_path!(parsed[:type], parsed[:path])

          { type: parsed[:type], full_path: parent.full_path, record: parent }
        end

        def resolve_work_item_from_url(url)
          parsed = parse_work_item_url(url)
          parent = find_parent_by_id_or_path!(parsed[:parent_type], parsed[:parent_path])
          work_item = find_work_item_in_parent!(parent, parsed[:work_item_iid])

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
          match = path.match(WORK_ITEM_URL_PATTERN)

          raise ArgumentError, "Invalid work item URL format. Expected: .../-/work_items/<iid>" unless match

          parent_path = match[:path]
          parent_type = path.start_with?('groups/') ? :group : :project

          { parent_type: parent_type, parent_path: parent_path, work_item_iid: match[:id].to_i }
        end

        def extract_path_from_url(url)
          path = parse_url!(url).path

          strip_relative_url_root(path).delete_prefix('/')
        end

        def parse_url!(url)
          uri = URI.parse(url)
          raise ArgumentError, "Invalid URL format: #{url}" unless %w[http https].include?(uri.scheme)

          uri
        rescue URI::BadURIError, URI::InvalidURIError => e
          raise ArgumentError, "Invalid URL format: #{e.message}"
        end

        # Instances served under a relative URL root (e.g. `/gitlab` or a GDK's
        # `/gdk-instance`) include that prefix in work item URLs. Strip it so the
        # remaining path resolves to the actual group/project full path.
        def strip_relative_url_root(path)
          regex = self.class.relative_url_root_regex
          return path unless regex

          path.sub(regex, '')
        end
      end
    end
  end
end
