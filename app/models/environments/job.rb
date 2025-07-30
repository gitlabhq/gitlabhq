# frozen_string_literal: true

module Environments
  class Job < ApplicationRecord
    self.table_name = 'job_environments'

    belongs_to :environment, optional: false
    belongs_to :project, optional: false
    belongs_to :pipeline, class_name: 'Ci::Pipeline', foreign_key: :ci_pipeline_id, optional: false,
      inverse_of: :job_environments
    belongs_to :job, class_name: 'Ci::Processable', foreign_key: :ci_job_id, optional: false,
      inverse_of: :job_environment
    belongs_to :deployment

    validates :ci_job_id, uniqueness: { scope: :environment_id }
    validates :options, json_schema: { filename: 'environments_job_options', size_limit: 256.bytes }
    validates :expanded_environment_name,
      presence: true,
      length: { maximum: 255 },
      format: { with: Gitlab::Regex.environment_name_regex,
                message: Gitlab::Regex.environment_name_regex_message }
  end
end
