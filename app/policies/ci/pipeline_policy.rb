module Ci
  class PipelinePolicy < BasePolicy
    delegate { @subject.project }
  end
end
