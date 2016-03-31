module Banzai
  module Filter
    # HTML filter that replaces milestone references with links.
    class MilestoneReferenceFilter < AbstractReferenceFilter
      def self.object_class
        Milestone
      end

      def find_object(project, id)
        project.milestones.find(id)
      end

      def references_in(text, pattern = Milestone.reference_pattern)
        text.gsub(pattern) do |match|
          project = project_from_ref($~[:project])
          params = milestone_params($~[:milestone_id].to_i, $~[:milestone_name])
          milestone = project.milestones.find_by(params)

          if milestone
            yield match, milestone.id, $~[:project], $~
          else
            match
          end
        end
      end

      def url_for_object(milestone, project)
        h = Gitlab::Routing.url_helpers
        h.namespace_project_milestone_url(project.namespace, project, milestone,
                                        only_path: context[:only_path])
      end

      def milestone_params(id, name)
        if name
          { name: name.tr('"', '') }
        else
          { id: id }
        end
      end
    end
  end
end
