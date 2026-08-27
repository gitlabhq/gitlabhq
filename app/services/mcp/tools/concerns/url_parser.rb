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

        WORK_ITEM_URL_PATTERN = %r{\A/?(?:groups/)?(?<path>\S*)/-/(?<segment>work_items|issues|epics)/(?<id>\d+)\z}

        BLOB_URL_PATTERN = %r{\A(?<project_path>.+?)/-/(?:blob|raw|blame)/(?<id>.+)\z}

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

        # Parse work item URL. Issues and epics are work items, so their URL forms
        # resolve through the same parent + iid lookup.
        # Examples:
        #   https://gitlab.com/namespace/project/-/work_items/42
        #   https://gitlab.com/namespace/project/-/issues/42
        #   https://gitlab.com/groups/namespace/group/-/work_items/42
        #   https://gitlab.com/groups/namespace/group/-/epics/42
        def parse_work_item_url(url)
          path = extract_path_from_url(url)
          match = path.match(WORK_ITEM_URL_PATTERN)

          unless match
            raise ArgumentError, 'Invalid work item URL format. ' \
              'Expected: .../-/work_items/<iid>, .../-/issues/<iid>, or .../-/epics/<iid>'
          end

          parent_path = match[:path]
          parent_type = path.start_with?('groups/') ? :group : :project
          validate_segment_context!(match[:segment], parent_type)

          { parent_type: parent_type, parent_path: parent_path, work_item_iid: match[:id].to_i }
        end

        # Issue URLs only exist on projects and epic URLs only on groups; accepting
        # the crossed forms would resolve whatever work item shares the iid in the
        # wrong parent instead of failing fast.
        def validate_segment_context!(segment, parent_type)
          crossed = (segment == 'issues' && parent_type == :group) ||
            (segment == 'epics' && parent_type == :project)
          return unless crossed

          raise ArgumentError, 'Invalid work item URL format. Issue URLs belong to projects ' \
            'and epic URLs belong to groups.'
        end

        def parse_blob_url(url)
          path = extract_path_from_url(url)
          match = path.match(BLOB_URL_PATTERN)

          raise ArgumentError, "Invalid file URL format. Expected: .../-/blob/<ref>/<file_path>" unless match

          {
            project_path: match[:project_path],
            id: unescape_and_scrub_uri(match[:id]),
            ref_type: ref_type_from_url(url)
          }
        end

        def ref_type_from_url(url)
          query = parse_url!(url).query
          return if query.blank?

          ::ExtractsRef::RefExtractor.ref_type(Rack::Utils.parse_nested_query(query)['ref_type'])
        end

        def unescape_and_scrub_uri(uri)
          Addressable::URI.unescape(uri).scrub.delete("\0")
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
