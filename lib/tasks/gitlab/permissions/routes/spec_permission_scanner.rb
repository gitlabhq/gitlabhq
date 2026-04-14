# frozen_string_literal: true

module Tasks
  module Gitlab
    module Permissions
      module Routes
        # Scans spec files for `it_behaves_like 'authorizing granular token permissions'`
        # to determine which permissions have test coverage.
        class SpecPermissionScanner
          # Matches permission symbols after `it_behaves_like 'authorizing granular token permissions'`
          # Also matches wrapper shared examples like 'granular token permissions authorizable'
          # Handles: :symbol, [:sym1, :sym2], %i[sym1 sym2], and dynamic variables (ignored)
          PERMISSION_TEST_LINE_PATTERN = %r{
            it_behaves_like\s+['"]
            (?:authorizing\sgranular\stoken\spermissions|granular\stoken\spermissions\sauthorizable)
            ['"]\s*,\s*(.*)
          }x

          TODO_FILE = ::Rails.root.join('config/authz/routes/test_coverage_todo.txt')
          EACH_LOOP_LOOKBACK_LINES = 15

          SPEC_DIRS = %w[
            spec/requests/api
            ee/spec/requests/api
            ee/spec/requests/ee/api
            spec/support/shared_examples/requests/api
            ee/spec/support/shared_examples/requests/api
          ].freeze

          SHARED_EXAMPLES_PATTERN = /^(\s*)(?:RSpec\.)?shared_examples(?:_for)?\s+['"](.+?)['"]/

          def initialize(root_path = Rails.root)
            @root_path = root_path
            @route_counts = Hash.new(0)
            @route_details = Hash.new { |h, k| h[k] = [] }
            @seen_route_permissions = Set.new
          end

          # Registers a route for test coverage tracking.
          # Call once per route+permission combination.
          # route_id: "GET /projects/:id/notes"
          # permission: :read_note
          # route_info: { method:, path:, source:, spec_file: }
          def add_route(route_id:, permission:, route_info:)
            key = "#{route_id} #{permission}"
            return if @seen_route_permissions.include?(key)

            @seen_route_permissions << key
            perm = permission.to_s
            @route_counts[perm] += 1
            @route_details[perm] << route_info
          end

          # Returns permissions with fewer tests than routes.
          # Each entry: { permission:, route_count:, test_count:, routes: [...] }
          def insufficient_test_coverage
            ensure_scanned!

            violations = []

            @route_counts.each do |permission, route_count|
              next if in_todo?(permission)

              tc = test_count(permission)
              next if tc >= route_count

              violations << {
                permission: permission,
                route_count: route_count,
                test_count: tc,
                routes: @route_details[permission]
              }
            end

            violations
          end

          # Returns how many times this permission appears in test files.
          # Checks both concrete permission names and dynamic regex patterns.
          def test_count(permission)
            ensure_scanned!

            perm = permission.to_s
            count = @test_counts[perm]
            @dynamic_patterns.each { |entry| count += entry[:count] if entry[:pattern].match?(perm) }
            count
          end

          # Returns true if this permission is listed in the TODO file.
          def in_todo?(permission)
            todo_entries.include?(permission.to_s)
          end

          # Derives the suggested spec file path from an API source file path.
          # Used in error messages as a hint -- the scanner checks all spec dirs globally,
          # not just this path.
          # e.g. lib/api/notes.rb        -> spec/requests/api/notes_spec.rb
          #      ee/lib/api/epics.rb     -> ee/spec/requests/api/epics_spec.rb
          #      ee/lib/ee/api/groups.rb -> ee/spec/requests/api/groups_spec.rb
          def derive_spec_path(source_file)
            source_file
              .sub(%r{^ee/lib/ee/api/}, 'ee/spec/requests/api/')
              .sub(%r{^ee/lib/api/}, 'ee/spec/requests/api/')
              .sub(%r{^lib/api/}, 'spec/requests/api/')
              .sub(/\.rb$/, '_spec.rb')
          end

          private

          def spec_files
            @spec_files ||= SPEC_DIRS.flat_map { |dir| Dir.glob(@root_path.join("#{dir}/**/*.rb")) }
          end

          def file_lines(file)
            @file_lines_cache ||= {}
            @file_lines_cache[file] ||= File.read(file).lines
          end

          # Scans all spec files once and populates @test_counts and @dynamic_patterns.
          def ensure_scanned!
            return if @scanned

            @test_counts = Hash.new(0)
            @dynamic_patterns = []

            inclusions = build_shared_example_inclusions

            spec_files.each do |file|
              scan_file(file, inclusions)
            end

            @scanned = true
          end

          # Counts how many times each shared_examples block is included across all spec files.
          # Accounts for .each loops wrapping it_behaves_like calls.
          # Returns { "example name" => count }.
          def build_shared_example_inclusions
            counts = Hash.new(0)

            spec_files.each do |file|
              lines = file_lines(file)

              lines.each_with_index do |line, idx|
                match = line.match(/(?:it_behaves_like|include_examples)\s+['"](.+?)['"]/)
                next unless match

                counts[match[1]] += each_loop_multiplier(lines, idx)
              end
            end

            counts
          end

          # Checks if a line is inside an .each block by walking backwards to find
          # %w[...].each, %i[...].each, or [...].each patterns. Returns the array size
          # as multiplier, or 1 if not inside an each loop.
          # Handles arrays spanning multiple lines.
          def each_loop_multiplier(lines, line_idx)
            line_indent = lines[line_idx][/^ */].length
            multiplier = nil

            line_idx.downto([line_idx - EACH_LOOP_LOOKBACK_LINES, 0].max) do |i|
              each_line = lines[i]
              each_indent = each_line[/^ */].length

              # Only consider blocks at a lower indentation level
              next unless each_indent < line_indent

              # Join consecutive lines to handle multiline arrays
              joined = lines[i..[i + 5, line_idx - 1].min].join

              m = joined.match(/%[wi]\[([^\]]*)\]\.each/)
              if m
                multiplier = m[1].split.length
                break
              end

              m = joined.match(/\[([^\]]*)\]\.each/)
              if m
                multiplier = m[1].split(',').length
                break
              end

              # Stop at any block-opener at a lower indentation -- not inside .each
              break if each_line.match?(/\bdo\b|\{/)
            end

            multiplier || 1
          end

          def scan_file(file, inclusions)
            lines = file_lines(file)

            lines.each_with_index do |line, idx|
              match = line.match(PERMISSION_TEST_LINE_PATTERN)
              next unless match

              args = match[1].strip

              # Handle multiline: permission on the next line after trailing comma
              if args.empty?
                next_line = lines[idx + 1]&.strip
                args = next_line if next_line
              end

              multiplier = multiplier_for_line(file, idx, inclusions) * each_loop_multiplier(lines, idx)
              extract_permission_args(args).each do |entry|
                if entry.is_a?(Regexp)
                  existing = @dynamic_patterns.find { |e| e[:pattern] == entry }
                  if existing
                    existing[:count] += multiplier
                  else
                    @dynamic_patterns << { pattern: entry, count: multiplier }
                  end
                else
                  @test_counts[entry] += multiplier
                end
              end
            end
          end

          def extract_permission_args(args)
            results = []

            if args.match?(/^%i[\[(]/)
              bracket_content = args[/[\[(](.+?)[\])]/, 1]
              bracket_content&.scan(/(\w+)/) { |sym,| results << sym }
            elsif args.start_with?('[')
              args.scan(/:(\w+)/) { |sym,| results << sym }
            elsif args.match?(/^:".*\#\{/)
              results << build_dynamic_pattern(args)
            elsif args.start_with?(':')
              args.match(/:(\w+)/) { |m| results << m[1] }
            end

            results.compact
          end

          # Converts :"read_#{var}_discussion" into /\Aread_\w+_discussion\z/
          def build_dynamic_pattern(args)
            template = args.delete_prefix(':"')
            template = template.sub(/".*/, '') # strip trailing quote and anything after
            regex_str = Regexp.escape(template).gsub(/\\\#\\\{[^}]*\\\}/, '\\w+')
            Regexp.new("\\A#{regex_str}\\z")
          end

          # Determines how many times a permission test on a given line will run.
          # If the line is inside a shared_examples block, returns how many times
          # that block is included across all spec files. Otherwise returns 1.
          def multiplier_for_line(file, line_idx, inclusions)
            enclosing = shared_example_map(file)[line_idx]
            return 1 unless enclosing

            inclusions.fetch(enclosing, 0)
          end

          # Pre-computes a map of line_index => enclosing shared_examples name.
          # Uses indentation to determine block boundaries: lines indented deeper
          # than the shared_examples declaration are inside the block.
          def shared_example_map(file)
            @shared_example_maps ||= {}
            @shared_example_maps[file] ||= build_shared_example_map(file_lines(file))
          end

          def build_shared_example_map(lines)
            map = {}
            stack = [] # [{name:, indent:}] for nested shared_examples

            lines.each_with_index do |line, idx|
              indent = line[/^ */].length

              # Close any blocks at the same or lower indentation
              stack.pop while stack.any? && !line.strip.empty? && indent <= stack.last[:indent]

              match = line.match(SHARED_EXAMPLES_PATTERN)
              if match
                stack.push({ name: match[2], indent: match[1].length })
                next
              end

              map[idx] = stack.last[:name] if stack.any?
            end

            map
          end

          def todo_entries
            @todo_entries ||= load_todo_entries
          end

          def load_todo_entries
            return Set.new unless TODO_FILE.exist?

            TODO_FILE.readlines.each_with_object(Set.new) do |line, set|
              stripped = line.strip
              set << stripped unless stripped.empty? || stripped.start_with?('#')
            end
          end
        end
      end
    end
  end
end
