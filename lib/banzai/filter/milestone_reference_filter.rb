# frozen_string_literal: true

module Banzai
  module Filter
    # HTML filter that replaces milestone references with links.
    class MilestoneReferenceFilter < AbstractReferenceFilter
      include Gitlab::Utils::StrongMemoize

      self.reference_type = :milestone

      def self.object_class
        Milestone
      end

      # Links to project milestones contain the IID, but when we're handling
      # 'regular' references, we need to use the global ID to disambiguate
      # between group and project milestones.
      def find_object(parent, id)
        return unless valid_context?(parent)

        find_milestone_with_finder(parent, id: id)
      end

      def find_object_from_link(parent, iid)
        return unless valid_context?(parent)

        find_milestone_with_finder(parent, iid: iid)
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
        unescaped_html = unescape_html_entities(text).gsub(pattern) do |match|
          milestone = find_milestone($~[:project], $~[:namespace], $~[:milestone_iid], $~[:milestone_name])

          if milestone
            milestones[milestone.id] = yield match, milestone.id, $~[:project], $~[:namespace], $~
            "#{REFERENCE_PLACEHOLDER}#{milestone.id}"
          else
            match
          end
        end

        return text if milestones.empty?

        escape_with_placeholders(unescaped_html, milestones)
      end

      def find_milestone(project_ref, namespace_ref, milestone_id, milestone_name)
        project_path = full_project_path(namespace_ref, project_ref)

        # Returns group if project is not found by path
        parent = parent_from_ref(project_path)

        return unless parent

        milestone_params = milestone_params(milestone_id, milestone_name)

        find_milestone_with_finder(parent, milestone_params)
      end

      def milestone_params(iid, name)
        if name
          { name: name.tr('"', '') }
        else
          { iid: iid.to_i }
        end
      end

      def find_milestone_with_finder(parent, params)
        finder_params = milestone_finder_params(parent, params[:iid].present?)

        MilestonesFinder.new(finder_params).find_by(params)
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
        reference = object.project&.to_reference(project)

        if reference.present?
          "#{milestone_link} <i>in #{reference}</i>".html_safe
        else
          milestone_link
        end
      end

      def object_link_title(object, matches)
        nil
      end
    end
  end
end
