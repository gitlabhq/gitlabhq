# frozen_string_literal: true

module Ci
  class PipelineChatData < Ci::ApplicationRecord
    include Ci::NamespacedModelName
    include IgnorableColumns

    ignore_column :pipeline_id_convert_to_bigint, remove_with: '16.5', remove_after: '2023-10-22'

    self.table_name = 'ci_pipeline_chat_data'

    belongs_to :chat_name

    validates :pipeline_id, presence: true
    validates :chat_name_id, presence: true
    validates :response_url, presence: true
  end
end
