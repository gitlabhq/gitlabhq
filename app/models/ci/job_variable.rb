# frozen_string_literal: true

module Ci
  class JobVariable < Ci::ApplicationRecord
    include Ci::Partitionable
    include Ci::NewHasVariable
    include Ci::RawVariable
    include BulkInsertSafe

    belongs_to :job, class_name: "Ci::Build", foreign_key: :job_id, inverse_of: :job_variables

    partitionable scope: :job

    alias_attribute :secret_value, :value

    validates :key, uniqueness: { scope: :job_id }, unless: :dotenv_source?

    enum source: { internal: 0, dotenv: 1 }, _suffix: true
  end
end
