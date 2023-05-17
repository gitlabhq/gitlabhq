# rubocop:disable Style/ClassAndModuleChildren
# frozen_string_literal: true

class MergeRequest::DiffLlmSummary < ApplicationRecord
  belongs_to :merge_request_diff
  belongs_to :user, optional: true

  validates :provider, presence: true
  validates :content, presence: true, length: { maximum: 2056 }

  enum provider: { openai: 0 }
end
# rubocop:enable Style/ClassAndModuleChildren
