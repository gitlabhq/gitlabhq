# frozen_string_literal: true

require "json"

module Gitlab
  module Cells
    module HttpRouter
      # Compares two serialized routing snapshots: the one committed in GitLab and
      # the copy the HTTP Router mirrors. The router replays the examples in its
      # own copy, so a route GitLab knows about and the router does not can be
      # classified to the wrong cell.
      #
      # The verdict is byte equality, because the router parses this file and a
      # serialization change matters as much as a missing route. The template sets
      # are compared separately, only to explain a byte difference in terms a
      # route author can act on.
      class SnapshotComparison
        # A payload with fewer routes than this is a truncated response or an
        # error page rather than a snapshot. Real snapshots hold thousands.
        MIN_ROUTES = 1000

        # Carries the side that failed, so a caller can report a bad download
        # separately from a bad file on the branch.
        class InvalidSnapshotError < StandardError
          LABELS = { gitlab: "The GitLab snapshot", router: "The HTTP Router snapshot" }.freeze

          attr_reader :source

          def initialize(source, message)
            @source = source

            super("#{LABELS.fetch(source)} #{message}")
          end
        end

        # Raises InvalidSnapshotError rather than returning a comparison, so a
        # caller can report a bad download separately from route drift. Reporting
        # them the same way would let a 404 HTML page read as wholesale drift.
        def self.parse(payload, source:)
          routes = begin
            JSON.parse(payload)
          rescue JSON::ParserError => e
            raise InvalidSnapshotError.new(source, "is not valid JSON: #{e.message}")
          end

          unless routes.is_a?(Array)
            raise InvalidSnapshotError.new(source, "is #{routes.class}, expected an array of routes")
          end

          if routes.size < MIN_ROUTES
            raise InvalidSnapshotError.new(source,
              "holds only #{routes.size} routes, expected at least #{MIN_ROUTES}")
          end

          templates = routes.map { |route| route["template"] if route.is_a?(Hash) }

          if templates.any? { |template| !template.is_a?(String) || template.empty? }
            raise InvalidSnapshotError.new(source, "has an entry without a template")
          end

          templates
        end

        attr_reader :gitlab_only, :router_only

        # Both arguments are the raw file contents, compared verbatim.
        def initialize(gitlab_payload:, router_payload:)
          @identical = gitlab_payload == router_payload

          gitlab_templates = self.class.parse(gitlab_payload, source: :gitlab)
          router_templates = self.class.parse(router_payload, source: :router)

          @gitlab_only = (gitlab_templates - router_templates).sort
          @router_only = (router_templates - gitlab_templates).sort
        end

        def identical?
          @identical
        end

        # True when the byte comparison failed but both sides carry the same
        # routes, so only the serialization or the per-route fields moved.
        def formatting_only?
          !identical? && gitlab_only.empty? && router_only.empty?
        end
      end
    end
  end
end
