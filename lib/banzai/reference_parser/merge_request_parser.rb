module Banzai
  module ReferenceParser
    class MergeRequestParser < IssuableParser
      self.reference_type = :merge_request

      def records_for_nodes(nodes)
        @merge_requests_for_nodes ||= grouped_objects_for_nodes(
          nodes,
          MergeRequest.includes(
            :author,
            :assignee,
            {
              # These associations are primarily used for checking permissions.
              # Eager loading these ensures we don't end up running dozens of
              # queries in this process.
              target_project: [
                { namespace: :owner },
                { group: [:owners, :group_members] },
                :invited_groups,
                :project_members,
                :project_feature
              ]
            }),
          self.class.data_attribute
        )
      end
    end
  end
end
