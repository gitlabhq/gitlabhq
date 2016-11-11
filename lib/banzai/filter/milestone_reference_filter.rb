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
          milestone = find_milestone($~[:project], $~[:milestone_iid], $~[:milestone_name])

          if milestone
            yield match, milestone.iid, $~[:project], $~
          else
            match
          end
        end
      end

      def find_milestone(project_ref, milestone_id, milestone_name)
        project = project_from_ref(project_ref)
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
        h.namespace_project_milestone_url(project.namespace, project, milestone,
                                        only_path: context[:only_path])
      end

      def object_link_text(object, matches)
        if context[:project] == object.project
          super
        else
          "#{escape_once(super)} <i>in #{escape_once(object.project.path_with_namespace)}</i>".
            html_safe
        end
      end

      def object_link_title(object)
        nil
      end
    end
  end
end
