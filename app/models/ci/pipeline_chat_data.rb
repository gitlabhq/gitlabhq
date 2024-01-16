# frozen_string_literal: true

module Ci
  class PipelineChatData < Ci::ApplicationRecord
    include Ci::Partitionable
    include Ci::NamespacedModelName
    include SafelyChangeColumnDefault

    columns_changing_default :partition_id

    self.table_name = 'ci_pipeline_chat_data'

    belongs_to :chat_name
    belongs_to :pipeline

    validates :pipeline_id, presence: true
    validates :chat_name_id, presence: true
    validates :response_url, presence: true

    partitionable scope: :pipeline
  end
end
