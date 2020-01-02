# frozen_string_literal: true

class ResourceWeightEvent < ApplicationRecord
  include Gitlab::Utils::StrongMemoize

  validates :user, presence: true
  validates :issue, presence: true

  belongs_to :user
  belongs_to :issue

  scope :by_issue, ->(issue) { where(issue_id: issue.id) }
  scope :created_after, ->(time) { where('created_at > ?', time) }

  def discussion_id(resource = nil)
    strong_memoize(:discussion_id) do
      Digest::SHA1.hexdigest(discussion_id_key.join("-"))
    end
  end

  private

  def discussion_id_key
    [self.class.name, created_at, user_id]
  end
end
