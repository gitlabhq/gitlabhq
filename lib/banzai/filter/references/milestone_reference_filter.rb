# frozen_string_literal: true

module Banzai
  module Filter
    module References
      # HTML filter that replaces milestone references with links.
      class MilestoneReferenceFilter < AbstractReferenceFilter
        include Gitlab::Utils::StrongMemoize

        self.reference_type = :milestone
        self.object_class   = Milestone

        def parent_records(parent, ids)
          return Milestone.none unless valid_context?(parent)

          milestone_iids = ids.map {|y| y[:milestone_iid]}.compact
          unless milestone_iids.empty?
            iid_relation = find_milestones(parent, true).where(iid: milestone_iids)
          end

          milestone_names = ids.map {|y| y[:milestone_name]}.compact
          unless milestone_names.empty?
            milestone_relation = find_milestones(parent, false).where(name: milestone_names)
          end

          return Milestone.none if (relation = [iid_relation, milestone_relation].compact).empty?

          Milestone.from_union(relation).includes(:project, :group)
        end

        def find_object(parent_object, id)
          key = reference_cache.records_per_parent[parent_object].keys.find do |k|
            k[:milestone_iid] == id[:milestone_iid] || k[:milestone_name] == id[:milestone_name]
          end

          reference_cache.records_per_parent[parent_object][key] if key
        end

        # Transform a symbol extracted from the text to a meaningful value
        #
        # This method has the contract that if a string `ref` refers to a
        # record `record`, then `parse_symbol(ref) == record_identifier(record)`.
        #
        # This contract is slightly broken here, as we only have either the milestone_iid
        # or the milestone_name, but not both.  But below, we have both pieces of information.
        # But it's accounted for in `find_object`
        def parse_symbol(symbol, match_data)
          if symbol
            # when parsing links, there is no `match_data[:milestone_iid]`, but `symbol`
            # holds the iid
            { milestone_iid: symbol.to_i, milestone_name: nil }
          else
            { milestone_iid: match_data[:milestone_iid]&.to_i, milestone_name: match_data[:milestone_name]&.tr('"', '') }
          end
        end

        # This method has the contract that if a string `ref` refers to a
        # record `record`, then `class.parse_symbol(ref) == record_identifier(record)`.
        # See note in `parse_symbol` above
        def record_identifier(record)
          { milestone_iid: record.iid, milestone_name: record.name }
        end

        def valid_context?(parent)
          strong_memoize(:valid_context) do
            group_context?(parent) || project_context?(parent)
          end
        end

        def group_context?(parent)
          strong_memoize(:group_context) do
            parent.is_a?(Group)
          end
        end

        def project_context?(parent)
          strong_memoize(:project_context) do
            parent.is_a?(Project)
          end
        end

        def references_in(text, pattern = Milestone.reference_pattern)
          # We'll handle here the references that follow the `reference_pattern`.
          # Other patterns (for example, the link pattern) are handled by the
          # default implementation.
          return super(text, pattern) if pattern != Milestone.reference_pattern

          milestones = {}

          unescaped_html = unescape_html_entities(text).gsub(pattern).with_index do |match, index|
            ident = identifier($~)
            milestone = yield match, ident, $~[:project], $~[:namespace], $~

            if milestone != match
              milestones[index] = milestone
              "#{REFERENCE_PLACEHOLDER}#{index}"
            else
              match
            end
          end

          return text if milestones.empty?

          escape_with_placeholders(unescaped_html, milestones)
        end

        def find_milestones(parent, find_by_iid = false)
          finder_params = milestone_finder_params(parent, find_by_iid)

          MilestonesFinder.new(finder_params).execute
        end

        def milestone_finder_params(parent, find_by_iid)
          { order: nil, state: 'all' }.tap do |params|
            params[:project_ids] = parent.id if project_context?(parent)

            # We don't support IID lookups because IIDs can clash between
            # group/project milestones and group/subgroup milestones.
            params[:group_ids] = self_and_ancestors_ids(parent) unless find_by_iid
          end
        end

        def self_and_ancestors_ids(parent)
          if group_context?(parent)
            parent.self_and_ancestors.select(:id)
          elsif project_context?(parent)
            parent.group&.self_and_ancestors&.select(:id)
          end
        end

        def url_for_object(milestone, project)
          Gitlab::Routing
            .url_helpers
            .milestone_url(milestone, only_path: context[:only_path])
        end

        def object_link_text(object, matches)
          milestone_link = escape_once(super)
          reference = object.project&.to_reference_base(project)

          if reference.present?
            "#{milestone_link} <i>in #{reference}</i>".html_safe
          else
            milestone_link
          end
        end

        def object_link_title(object, matches)
          nil
        end

        def parent
          project || group
        end

        def requires_unescaping?
          true
        end
      end
    end
  end
end
