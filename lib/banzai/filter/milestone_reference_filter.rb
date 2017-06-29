module Banzai
  module Filter
    # HTML filter that replaces milestone references with links.
    class MilestoneReferenceFilter < AbstractReferenceFilter
      self.reference_type = :milestone

      def self.object_class
        Milestone
      end

      def find_object(project, id)
        project.milestones.find_by(iid: id)
      end

      def references_in(text, pattern = Milestone.reference_pattern)
        # We'll handle here the references that follow the `reference_pattern`.
        # Other patterns (for example, the link pattern) are handled by the
        # default implementation.
        return super(text, pattern) if pattern != Milestone.reference_pattern

        text.gsub(pattern) do |match|
          milestone = find_milestone($~[:project], $~[:namespace], $~[:milestone_iid], $~[:milestone_name])

          if milestone
            yield match, milestone.iid, $~[:project], $~[:namespace], $~
          else
            match
          end
        end
      end

      def find_milestone(project_ref, namespace_ref, milestone_id, milestone_name)
        project_path = full_project_path(namespace_ref, project_ref)
        project = project_from_ref(project_path)

        return unless project

        milestone_params = milestone_params(milestone_id, milestone_name)
        project.milestones.find_by(milestone_params)
      end

      def milestone_params(iid, name)
        if name
          { name: name.tr('"', '') }
        else
          { iid: iid.to_i }
        end
      end

      def url_for_object(milestone, project)
        h = Gitlab::Routing.url_helpers
        h.project_milestone_url(project, milestone,
                                        only_path: context[:only_path])
      end

      def object_link_text(object, matches)
        milestone_link = escape_once(super)
        reference = object.project.to_reference(project)

        if reference.present?
          "#{milestone_link} <i>in #{reference}</i>".html_safe
        else
          milestone_link
        end
      end

      def object_link_title(object)
        nil
      end
    end
  end
end
