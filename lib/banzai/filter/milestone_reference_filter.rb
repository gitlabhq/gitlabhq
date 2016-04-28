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

      def url_for_object(issue, project)
        h = Gitlab::Routing.url_helpers
        h.namespace_project_milestone_url(project.namespace, project, milestone,
                                        only_path: context[:only_path])
      end
    end
  end
end
