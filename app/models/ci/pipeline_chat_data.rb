# frozen_string_literal: true

module Ci
  class PipelineChatData < ApplicationRecord
    self.table_name = 'ci_pipeline_chat_data'

    belongs_to :chat_name

    validates :pipeline_id, presence: true
    validates :chat_name_id, presence: true
    validates :response_url, presence: true
  end
end
