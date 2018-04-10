module Banzai
  module Filter
    # HTML filter that replaces milestone references with links.
    class MilestoneReferenceFilter < AbstractReferenceFilter
      self.reference_type = :milestone

      def self.object_class
        Milestone
      end

      # Links to project milestones contain the IID, but when we're handling
      # 'regular' references, we need to use the global ID to disambiguate
      # between group and project milestones.
      def find_object(project, id)
        find_milestone_with_finder(project, id: id)
      end

      def find_object_from_link(project, iid)
        find_milestone_with_finder(project, iid: iid)
      end

      def references_in(text, pattern = Milestone.reference_pattern)
        # We'll handle here the references that follow the `reference_pattern`.
        # Other patterns (for example, the link pattern) are handled by the
        # default implementation.
        return super(text, pattern) if pattern != Milestone.reference_pattern

        text.gsub(pattern) do |match|
          milestone = find_milestone($~[:project], $~[:namespace], $~[:milestone_iid], $~[:milestone_name])

          if milestone
            yield match, milestone.id, $~[:project], $~[:namespace], $~
          else
            match
          end
        end
      end

      def find_milestone(project_ref, namespace_ref, milestone_id, milestone_name)
        project_path = full_project_path(namespace_ref, project_ref)
        project = parent_from_ref(project_path)

        return unless project

        milestone_params = milestone_params(milestone_id, milestone_name)

        find_milestone_with_finder(project, milestone_params)
      end

      def milestone_params(iid, name)
        if name
          { name: name.tr('"', '') }
        else
          { iid: iid.to_i }
        end
      end

      def find_milestone_with_finder(project, params)
        finder_params = { project_ids: [project.id], order: nil, state: 'all' }

        # We don't support IID lookups for group milestones, because IIDs can
        # clash between group and project milestones.
        if project.group && !params[:iid]
          finder_params[:group_ids] = [project.group.id]
        end

        MilestonesFinder.new(finder_params).find_by(params)
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
