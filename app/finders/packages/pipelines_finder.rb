# frozen_string_literal: true

module Packages
  class PipelinesFinder
    COLUMNS = %i[id iid project_id sha ref status source created_at updated_at user_id].freeze

    def initialize(pipeline_ids)
      @pipeline_ids = pipeline_ids
    end

    def execute
      ::Ci::Pipeline
        .id_in(pipeline_ids)
        .select(COLUMNS)
        .order_id_desc
    end

    private

    attr_reader :pipeline_ids
  end
end
