# frozen_string_literal: true

module Ci
  class JobVariable < Ci::ApplicationRecord
    include Ci::Partitionable
    include Ci::NewHasVariable
    include Ci::RawVariable
    include Ci::ProjectsWithVariablesQuery

    before_validation :set_project_id, on: :create

    include BulkInsertSafe

    belongs_to :job, class_name: "Ci::Build", foreign_key: :job_id, inverse_of: :job_variables

    partitionable scope: :job

    validates :key, uniqueness: { scope: :job_id }, unless: :dotenv_source?
    validates :project_id, presence: true, on: :create

    enum :source, { internal: 0, dotenv: 1 }, suffix: true

    scope :for_jobs, ->(jobs) { where(job: jobs) }

    def set_project_id
      self.project_id ||= job&.project_id
    end
  end
end
