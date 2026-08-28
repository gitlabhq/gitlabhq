# frozen_string_literal: true

require "json"
require "fileutils"

module Gitlab
  module Cells
    module HttpRouter
      # Turns raw Rails and Grape route path specs into the snapshot entries the
      # HTTP Router replays. Given `/groups/*group_id/-/milestones/:id(.:format)`
      # it produces the template `/groups/*group_id/-/milestones/:id` paired with
      # the example `/groups/foo/bar/-/milestones/foo`.
      #
      # The router downloads the generated file and replays each example against
      # its own routing table to detect drift from GitLab.
      class RoutesSnapshot
        Route = Struct.new(:template, :example, keyword_init: true)

        # Optional trailing format segment appended to most routes, e.g.
        # `/groups/:id(.:format)`. Dropped from the template.
        FORMAT_SUFFIX = "(.:format)"

        # Placeholders used while unwrapping optional `( ... )` segments, so that
        # escaped literal parentheses (e.g. the NuGet `FindPackagesById\(\)`
        # route) are preserved instead of being treated as optional segments.
        LPAREN_PLACEHOLDER = "__LPAREN__"
        RPAREN_PLACEHOLDER = "__RPAREN__"

        # Routes mounted only under RAILS_ENV=test. The snapshot describes the
        # routes the router classifies in production, and every template here also
        # becomes a reserved-word guard on the router side, so they are dropped.
        TEST_ONLY_TEMPLATES = %r{\A(/-/view_component/previews|/_system_test_entrypoint)}

        # Build a concrete, routable URL from a template by unwrapping optional
        # segments and substituting parameters with placeholder values.
        def self.example_for(template)
          example = template.dup

          # Protect escaped literal parentheses before unwrapping optionals.
          example = example.gsub('\(', LPAREN_PLACEHOLDER).gsub('\)', RPAREN_PLACEHOLDER)

          # Unwrap optional `( ... )` segments, innermost first. Loop until the
          # substitution stops making progress rather than until no `(` remains,
          # so an unbalanced parenthesis fails fast instead of spinning forever.
          loop do
            break unless example.include?("(")

            unwrapped = example.gsub(/\(([^()]*)\)/, '\1')
            break if unwrapped == example

            example = unwrapped
          end

          # Restore the escaped parentheses as literal characters.
          example = example.gsub(LPAREN_PLACEHOLDER, "(").gsub(RPAREN_PLACEHOLDER, ")")

          example
            .gsub(".:format", "")             # Drop any inline format segment
            .gsub("/api/:version", "/api/v4") # Pin the API version
            .gsub(/\*[a-z_]+/, "foo/bar")     # Wildcards -> foo/bar
            .gsub(/:[a-z_]+/, "foo")          # Named params -> foo
            .gsub(%r{//+}, "/")               # Collapse duplicate slashes
            .sub(%r{/+\z}, "")                # Remove trailing slashes
            .then { |path| path.empty? ? "/" : path } # Keep the root path
        end

        # @param path_specs [Array<String>] raw route path specs, format segment
        #   included, as read from the Rails and Grape route tables.
        def initialize(path_specs:)
          @path_specs = path_specs
        end

        def routes
          @routes ||= templates.map do |template|
            Route.new(template: template, example: self.class.example_for(template))
          end
        end

        def to_json_string
          entries = routes.map { |route| { template: route.template, example: route.example } }

          "#{JSON.pretty_generate(entries)}\n"
        end

        # @param path [String, Pathname] absolute path to write the snapshot to.
        def write!(path)
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, to_json_string)

          path
        end

        private

        attr_reader :path_specs

        def templates
          path_specs
            .map { |spec| normalize(spec) }
            .uniq
            .reject { |template| template.match?(TEST_ONLY_TEMPLATES) }
            .sort
        end

        # Drop the optional format segment; everything else is the template.
        def normalize(path)
          path.delete_suffix(FORMAT_SUFFIX)
        end
      end
    end
  end
end
