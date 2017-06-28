module Ci
  class PipelinePolicy < BasePolicy
    def rules
      delegate! @subject.project
    end
  end
end
