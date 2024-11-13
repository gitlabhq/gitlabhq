# frozen_string_literal: true

module Banzai
  module Filter
    module References
      # HTML filter that replaces work item references with links. References to
      # work items that do not exist are ignored.
      #
      # This filter supports cross-project references.
      class WorkItemReferenceFilter < IssueReferenceFilter
        self.reference_type = :work_item
        self.object_class   = WorkItem

        def parent_records(parent, ids)
          parent.work_items.where(iid: ids.to_a)
                .includes(:project, :namespace, ::Gitlab::Issues::TypeAssociationGetter.call)
        end

        def parent_type
          :namespace
        end

        def parent
          project&.project_namespace || group
        end

        private

        def additional_object_attributes(work_item)
          { work_item_type: work_item.work_item_type.base_type }
        end
      end
    end
  end
end
