# frozen_string_literal: true

module Mcp
  module Tools
    module Repositories
      class GetRepositoryFileTool < Mcp::Tools::Base::GraphqlTool
        include Gitlab::Utils::StrongMemoize
        include ::Mcp::Tools::Concerns::UrlParser
        include ::Mcp::Tools::Concerns::ResourceFinder

        DEFAULT_LIMIT = 500
        MAX_LIMIT = 2000
        MAX_WINDOW_BYTES = 1.megabyte

        def self.build_query
          load_graphql('repositories/get_repository_file.query.graphql')
        end

        register_version VERSIONS[:v0_1_0], {
          operation_name: 'project',
          graphql_operation: build_query
        }

        # Authorize read_code before the query, since ref/path extraction and the
        # exclusion check read the repository before the GraphQL fetch runs.
        def execute
          return excluded_response if file_excluded?(target[:project], target[:path])

          super
        end

        def build_variables
          {
            projectPath: target[:project].full_path,
            ref: target[:ref],
            filePaths: [target[:path]],
            refType: target[:ref_type]&.upcase
          }
        end

        protected

        def build_variables_v0_1_0
          build_variables
        end

        # CE has no context exclusions. Overridden in EE.
        def file_excluded?(_project, _path)
          false
        end

        private

        def target
          args = normalize(params)
          identifier = project_identifier(args)
          project = find_project!(identifier)
          authorize_read_code!(project, identifier)
          ref, path, ref_type = resolve_ref_and_path(project, args)

          { project: project, ref: ref, path: path, ref_type: ref_type }
        end
        strong_memoize_attr :target

        # Reuse find_project!'s wording so a private project the user cannot read is
        # indistinguishable from one that does not exist, preventing enumeration.
        def authorize_read_code!(project, identifier)
          return if ::Ability.allowed?(current_user, :read_code, project)

          raise ::Gitlab::Access::AccessDeniedError, "Project '#{identifier}' not found or inaccessible"
        end

        def normalize(arguments)
          arguments.to_h.with_indifferent_access
        end

        def project_identifier(args)
          return parse_blob_url(args[:url])[:project_path] if args[:url].present?

          raise ArgumentError, 'Provide either url, or project_id, file_path, and ref' if args[:project_id].blank?

          args[:project_id].to_s
        end

        def resolve_ref_and_path(project, args)
          return ref_and_path_from_ids(args) if args[:url].blank?

          parsed = parse_blob_url(args[:url])
          url_ref, url_path = ::ExtractsRef::RefExtractor.new(project, {}).extract_ref(parsed[:id])

          raise ArgumentError, "Invalid file URL: no file path found after the ref in #{args[:url]}" if url_path.blank?

          validate_url_consistency!(args, parsed, url_ref, url_path)

          [args[:ref].presence || url_ref, normalize_path(url_path), parsed[:ref_type]]
        end

        def ref_and_path_from_ids(args)
          if args[:ref].blank? || args[:file_path].blank?
            raise ArgumentError, 'Provide either url, or project_id, file_path, and ref'
          end

          [args[:ref], normalize_path(args[:file_path]), nil]
        end

        def validate_url_consistency!(args, parsed, url_ref, url_path)
          project_id = args[:project_id].to_s
          if project_id.include?('/') && project_id != parsed[:project_path]
            raise ArgumentError,
              "Project mismatch: project_id is '#{project_id}' but url contains '#{parsed[:project_path]}'"
          end

          if args[:file_path].present? && normalize_path(args[:file_path]) != normalize_path(url_path)
            raise ArgumentError, "File path mismatch: file_path is '#{args[:file_path]}' but url contains '#{url_path}'"
          end

          return if args[:ref].blank? || args[:ref] == url_ref

          raise ArgumentError, "Ref mismatch: ref is '#{args[:ref]}' but url contains '#{url_ref}'"
        end

        def normalize_path(raw)
          path = raw.to_s.strip.delete_prefix('/')

          raise ArgumentError, 'file_path must not be empty' if path.blank?
          raise ArgumentError, "file_path must be a file, not a directory: '#{path}'" if path.end_with?('/')

          if ::Gitlab::PathTraversal.path_traversal?(path)
            raise ArgumentError, "file_path must not contain a path traversal sequence: '#{path}'"
          end

          path
        end

        def process_result(result)
          if result['errors'].present?
            return ::Mcp::Tools::Base::Response.error(extract_error_messages(result['errors']).join(', '))
          end

          node = result.dig('data', 'project', 'repository', 'blobs', 'nodes')&.first
          return blob_missing_response if node.nil?
          return lfs_response(node) if node['storedExternally']
          # rawTextBlob is null for binary content (requesting rawBlob would raise a UTF-8 error).
          return binary_response(node) if node['rawTextBlob'].nil?

          file_response(node)
        end

        def file_response(node)
          args = normalize(params)
          data = node['rawTextBlob'].to_s
          size = node['rawSize'].to_i
          fetch_truncated = size > data.bytesize

          lines = data.lines
          total = lines.size
          offset = [args[:offset].to_i, 0].max
          limit = args[:limit] || DEFAULT_LIMIT
          window, cap_reason = cap_window_bytes(lines[offset, limit] || [])
          last = offset + window.size
          remaining = [total - last, 0].max

          payload = {
            path: target[:path],
            ref: target[:ref],
            metadata: {
              total_lines: total,
              returned_lines: window.empty? ? nil : { start: offset + 1, end: last },
              truncated: window.size < total || fetch_truncated || cap_reason.present?,
              size_bytes: size
            },
            content: window.join
          }

          instruction = system_instruction(
            offset: offset, limit: limit, total: total, next_offset: last,
            remaining: remaining, empty: window.empty?, file_truncated: fetch_truncated,
            cap_reason: cap_reason
          )
          payload[:system_instruction] = instruction if instruction.present?

          success(payload)
        end

        # Bound the returned window by bytes so a few very long (e.g. minified) lines cannot
        # produce an unbounded response. Returns [capped_lines, cap_reason] where cap_reason is
        # nil, :dropped_lines (whole trailing lines omitted) or :line_cut (a single oversized
        # line was sliced mid-line and its remainder is lost).
        def cap_window_bytes(window)
          capped = []
          bytes = 0

          window.each do |line|
            break if capped.any? && bytes + line.bytesize > MAX_WINDOW_BYTES

            capped << line
            bytes += line.bytesize
            break if bytes >= MAX_WINDOW_BYTES
          end

          if capped.size == 1 && bytes > MAX_WINDOW_BYTES
            return [[capped.first.byteslice(0, MAX_WINDOW_BYTES).scrub], :line_cut]
          end

          [capped, capped.size < window.size ? :dropped_lines : nil]
        end

        def system_instruction(offset:, limit:, total:, next_offset:, remaining:, empty:, file_truncated:, cap_reason:)
          notes = []

          if empty && total > 0
            notes << "Offset #{offset} is past the end of the file (#{total} lines). " \
              "Call again with an offset below #{total}."
          elsif remaining > 0
            notes << "File truncated. Remaining lines: #{remaining}. To view more, call again with " \
              "{\"offset\": #{next_offset}, \"limit\": #{limit}}."
          end

          case cap_reason
          when :line_cut
            notes << "A line exceeded the #{MAX_WINDOW_BYTES} byte response limit and was cut; " \
              "its remainder is not retrievable due to size."
          when :dropped_lines
            notes << "The window was shortened to stay within the #{MAX_WINDOW_BYTES} byte response limit."
          end

          if file_truncated
            notes << "This file is larger than the read limit, so total_lines counts only the portion that " \
              "was retrieved. size_bytes is the full size."
          end

          notes.join(' ')
        end

        def success(payload)
          ::Mcp::Tools::Base::Response.success(
            [{ type: 'text', text: Gitlab::Json.dump(payload) }], payload
          )
        end

        def excluded_response
          ::Mcp::Tools::Base::Response.error(
            "File '#{target[:path]}' is excluded from AI context by this project's settings and cannot be read."
          )
        end

        # An empty blobs connection means either the ref does not exist or the file does not exist
        # at that ref. GraphQL cannot tell them apart, so resolve it with one commit lookup and
        # return the message that points the agent at the right next action.
        def blob_missing_response
          return ref_not_found_response unless ref_exists?

          file_not_found_response
        end

        def ref_exists?
          target[:project].repository.commit(target[:ref]).present?
        end

        def ref_not_found_response
          ::Mcp::Tools::Base::Response.error(
            "Ref '#{target[:ref]}' not found. Provide an existing branch name, tag name, or commit SHA, " \
              "or use HEAD for the default branch."
          )
        end

        def file_not_found_response
          ::Mcp::Tools::Base::Response.error(
            "File '#{target[:path]}' does not exist at ref '#{target[:ref]}'. The path must be relative to the " \
              "repository root. Do not retry the same path; use the search tool with scope 'blobs' to locate the file."
          )
        end

        def lfs_response(node)
          ::Mcp::Tools::Base::Response.error(
            "File '#{target[:path]}' is stored in LFS (#{node['externalStorage']}) and its content cannot be read " \
              "with this tool. Size: #{node['rawSize']} bytes."
          )
        end

        def binary_response(node)
          ::Mcp::Tools::Base::Response.error(
            "File '#{target[:path]}' is binary and cannot be returned as text. Size: #{node['rawSize']} bytes."
          )
        end
      end
    end
  end
end

Mcp::Tools::Repositories::GetRepositoryFileTool.prepend_mod
