# frozen_string_literal: true

module API
  module Entities
    class Bridge < Entities::JobBasic
      expose :downstream_pipeline, with: Entities::PipelineBasic
    end
  end
end
