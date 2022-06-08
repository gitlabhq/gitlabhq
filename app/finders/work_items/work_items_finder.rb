# frozen_string_literal: true

# WorkItem model inherits from Issue model. It's planned to be its extension
# with widgets support. Because WorkItems are internally Issues, WorkItemsFinder
# can be almost identical to IssuesFinder, except it should return instances of
# WorkItems instead of Issues
module WorkItems
  class WorkItemsFinder < IssuesFinder
    def params_class
      ::IssuesFinder::Params
    end

    private

    def model_class
      WorkItem
    end
  end
end
