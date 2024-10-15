# frozen_string_literal: true

module Ci
  class PipelineChatData < Ci::ApplicationRecord
    include Ci::Partitionable
    include Ci::NamespacedModelName

    self.table_name = 'ci_pipeline_chat_data'

    belongs_to :project
    belongs_to :chat_name
    belongs_to :pipeline

    validates :project_id, presence: true
    validates :pipeline_id, presence: true
    validates :chat_name_id, presence: true
    validates :response_url, presence: true

    partitionable scope: :pipeline
  end
end
