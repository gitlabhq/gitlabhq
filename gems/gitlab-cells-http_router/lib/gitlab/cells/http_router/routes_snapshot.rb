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
      # Where they apply, entries also carry adversarial variants the router
      # must classify the same way: `acceptsFormat` marks routes that accept a
      # format segment, and `dottedExample` carries an example built with dotted
      # parameter values. The consumer composes the `.json` variants itself,
      # including the combined dotted+format one.
      #
      # The router downloads the generated file and replays each example against
      # its own routing table to detect drift from GitLab.
      class RoutesSnapshot
        Route = Struct.new(
          :template, :example, :accepts_format, :dotted_example,
          keyword_init: true
        )

        # Optional trailing format segment appended to most routes, e.g.
        # `/groups/:id(.:format)`. Dropped from the template.
        FORMAT_SUFFIX = "(.:format)"

        # The format segment on its own. It also appears inline, e.g. the
        # `/-/archive/*id.:format` route.
        FORMAT_SEGMENT = ".:format"

        # Values substituted for named parameters and wildcards.
        PARAM_VALUE = "foo"
        GLOB_VALUE = "foo/bar"

        # Dotted variants of the same. A dot is legal in usernames and namespace
        # paths, so the router must not read one as a separator and truncate the
        # value it extracts.
        DOTTED_PARAM_VALUE = "john.doe"
        DOTTED_GLOB_VALUE = "john.doe/bar"

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
        #
        # @param param [String] value substituted for named parameters.
        # @param glob [String] value substituted for wildcards.
        # @return [String]
        def self.example_for(template, param: PARAM_VALUE, glob: GLOB_VALUE)
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
            .gsub(FORMAT_SEGMENT, "")         # Drop any inline format segment
            .gsub("/api/:version", "/api/v4") # Pin the API version
            .gsub(/\*[a-z_]+/, glob)          # Wildcards -> glob value
            .gsub(/:[a-z_]+/, param)          # Named params -> param value
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
            example = self.class.example_for(template)
            dotted = self.class.example_for(template, param: DOTTED_PARAM_VALUE, glob: DOTTED_GLOB_VALUE)
            # The two are equal when the template has no parameter to dot.
            dotted = nil if dotted == example

            Route.new(
              template: template,
              example: example,
              accepts_format: format_capable_templates.include?(template),
              dotted_example: dotted
            )
          end
        end

        def to_json_string
          entries = routes.map do |route|
            entry = { template: route.template, example: route.example }
            entry[:acceptsFormat] = true if route.accepts_format
            entry[:dottedExample] = route.dotted_example if route.dotted_example

            entry
          end

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

        # `normalize` drops the format segment before templates are deduped, so
        # the capability has to be recorded separately. Several raw specs can
        # normalize to the same template, and one format-capable spec is enough.
        def format_capable_templates
          @format_capable_templates ||= path_specs
            .filter_map { |spec| normalize(spec) if spec.include?(FORMAT_SEGMENT) }
            .to_set
        end

        # Drop the optional format segment; everything else is the template.
        def normalize(path)
          path.delete_suffix(FORMAT_SUFFIX)
        end
      end
    end
  end
end
