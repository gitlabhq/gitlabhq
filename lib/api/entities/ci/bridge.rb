# frozen_string_literal: true

module API
  module Entities
    module Ci
      class Bridge < JobBasic
        expose :downstream_pipeline, with: ::API::Entities::Ci::PipelineBasic
      end
    end
  end
end
