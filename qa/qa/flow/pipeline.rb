# frozen_string_literal: true

module QA
  module Flow
    module Pipeline
      module_function

      # In some cases we don't need to wait for anything, blocked, running or pending is acceptable
      # Some cases only need pipeline to finish with different condition (completion, success or replication)
      def visit_latest_pipeline(pipeline_condition: nil)
        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform(&:"wait_for_latest_pipeline_#{pipeline_condition}") if pipeline_condition
        Page::Project::Pipeline::Index.perform(&:click_on_latest_pipeline)
      end
    end
  end
end
