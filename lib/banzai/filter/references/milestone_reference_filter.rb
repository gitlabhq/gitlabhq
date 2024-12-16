# frozen_string_literal: true

module Banzai
  module Filter
    module References
      # HTML filter that replaces milestone references with links.
      class MilestoneReferenceFilter < AbstractReferenceFilter
        self.reference_type = :milestone
        self.object_class   = Milestone

        def parent_records(parent, ids)
          return Milestone.none unless valid_context?(parent)

          relation = []

          # We need to handle relative and absolute paths separately
          milestones_absolute_indexed = ids.group_by { |id| id[:absolute_path] }
          milestones_absolute_indexed.each do |absolute_path, fitered_ids|
            milestone_iids = fitered_ids&.pluck(:milestone_iid)&.compact

            if milestone_iids.present?
              relation << find_milestones(parent, true, absolute_path: absolute_path).where(iid: milestone_iids)
            end

            milestone_names = fitered_ids&.pluck(:milestone_name)&.compact
            if milestone_names.present?
              relation << find_milestones(parent, false, absolute_path: absolute_path).where(name: milestone_names)
            end
          end

          relation.compact!
          return Milestone.none if relation.all?(Milestone.none)

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
          absolute_path = !!match_data&.named_captures&.fetch('absolute_path')

          if symbol
            # when parsing links, there is no `match_data[:milestone_iid]`, but `symbol`
            # holds the iid
            { milestone_iid: symbol.to_i, milestone_name: nil, absolute_path: absolute_path }
          else
            { milestone_iid: match_data[:milestone_iid]&.to_i, milestone_name: match_data[:milestone_name]&.tr('"', ''), absolute_path: absolute_path }
          end
        end

        # This method has the contract that if a string `ref` refers to a
        # record `record`, then `class.parse_symbol(ref) == record_identifier(record)`.
        # See note in `parse_symbol` above
        def record_identifier(record)
          { milestone_iid: record.iid, milestone_name: record.name }
        end

        def valid_context?(parent)
          group_context?(parent) || project_context?(parent)
        end

        def group_context?(parent)
          parent.is_a?(Group)
        end

        def project_context?(parent)
          parent.is_a?(Project)
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

        def find_milestones(parent, find_by_iid = false, absolute_path: false)
          finder_params = milestone_finder_params(parent, find_by_iid, absolute_path)

          MilestonesFinder.new(finder_params).execute
        end

        def milestone_finder_params(parent, find_by_iid, absolute_path)
          { order: nil, state: 'all' }.tap do |params|
            params[:project_ids] = parent.id if project_context?(parent)

            # We don't support IID lookups because IIDs can clash between
            # group/project milestones and group/subgroup milestones.
            params[:group_ids] = group_and_ancestors_ids(parent, absolute_path) unless find_by_iid
          end
        end

        def group_and_ancestors_ids(parent, absolute_path)
          if group_context?(parent)
            absolute_path ? parent.id : parent.self_and_ancestors.select(:id)
          elsif project_context?(parent)
            absolute_path ? nil : parent.group&.self_and_ancestors&.select(:id)
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

        def data_attributes_for(text, parent, object, link_content: false, link_reference: false)
          object_parent = object.resource_parent

          return super unless object_parent.is_a?(Group)
          return super if object_parent.id == parent.id

          super.merge({ group: object_parent.id, namespace: object_parent.id, project: nil })
        end
      end
    end
  end
end
