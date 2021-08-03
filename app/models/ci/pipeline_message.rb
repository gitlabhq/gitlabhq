# frozen_string_literal: true

module Ci
  class PipelineMessage < Ci::ApplicationRecord
    MAX_CONTENT_LENGTH = 10_000

    belongs_to :pipeline

    validates :content, presence: true

    before_save :truncate_long_content

    enum severity: { error: 0, warning: 1 }

    private

    def truncate_long_content
      return if content.length <= MAX_CONTENT_LENGTH

      self.content = content.truncate(MAX_CONTENT_LENGTH)
    end
  end
end
