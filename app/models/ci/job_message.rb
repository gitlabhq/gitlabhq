# frozen_string_literal: true

module Ci
  class JobMessage < Ci::ApplicationRecord
    include Ci::Partitionable

    MAX_CONTENT_LENGTH = 10_000

    self.table_name = :p_ci_job_messages
    self.primary_key = :id

    query_constraints :id, :partition_id
    partitionable scope: :job, partitioned: true

    belongs_to :job,
      ->(job_message) { in_partition(job_message) },
      class_name: 'Ci::Processable',
      partition_foreign_key: :partition_id,
      inverse_of: :job_messages

    validates :project_id, presence: true
    validates :content, presence: true

    before_save :truncate_long_content

    enum :severity, { error: 0 }

    private

    def truncate_long_content
      return if content.length <= MAX_CONTENT_LENGTH

      self.content = content.truncate(MAX_CONTENT_LENGTH)
    end
  end
end
