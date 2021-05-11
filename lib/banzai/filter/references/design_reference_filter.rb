# frozen_string_literal: true

module Banzai
  module Filter
    module References
      class DesignReferenceFilter < AbstractReferenceFilter
        class Identifier
          include Comparable
          attr_reader :issue_iid, :filename

          def initialize(issue_iid:, filename:)
            @issue_iid = issue_iid
            @filename = filename
          end

          def as_composite_id(id_for_iid)
            id = id_for_iid[issue_iid]
            return unless id

            { issue_id: id, filename: filename }
          end

          def <=>(other)
            return unless other.is_a?(Identifier)

            [issue_iid, filename] <=> [other.issue_iid, other.filename]
          end
          alias_method :eql?, :==

          def hash
            [issue_iid, filename].hash
          end
        end

        self.reference_type = :design
        self.object_class   = ::DesignManagement::Design

        def find_object(project, identifier)
          reference_cache.records_per_parent[project][identifier]
        end

        def parent_records(project, identifiers)
          return [] unless project.design_management_enabled?

          iids        = identifiers.map(&:issue_iid).to_set
          issues      = project.issues.where(iid: iids)
          id_for_iid  = issues.index_by(&:iid).transform_values(&:id)
          issue_by_id = issues.index_by(&:id)

          designs(identifiers, id_for_iid).each do |d|
            issue = issue_by_id[d.issue_id]
            # optimisation: assign values we have already fetched
            d.project = project
            d.issue = issue
          end
        end

        def relation_for_paths(paths)
          super.includes(:route, :namespace, :group)
        end

        def url_for_object(design, project)
          path_options = { vueroute: design.filename }
          Gitlab::Routing.url_helpers.designs_project_issue_path(project, design.issue, path_options)
        end

        def data_attributes_for(_text, _project, design, **_kwargs)
          super.merge(issue: design.issue_id)
        end

        def object_sym
          :design
        end

        def parse_symbol(raw, match_data)
          filename = match_data[:url_filename]
          iid = match_data[:issue].to_i
          Identifier.new(filename: CGI.unescape(filename), issue_iid: iid)
        end

        def record_identifier(design)
          Identifier.new(filename: design.filename, issue_iid: design.issue.iid)
        end

        private

        def designs(identifiers, id_for_iid)
          identifiers
            .map { |identifier| identifier.as_composite_id(id_for_iid) }
            .compact
            .in_groups_of(100, false) # limitation of by_issue_id_and_filename, so we batch
            .flat_map { |ids| DesignManagement::Design.by_issue_id_and_filename(ids) }
        end
      end
    end
  end
end
