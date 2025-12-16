# frozen_string_literal: true

class ResourceEvent < ApplicationRecord
  include Gitlab::Utils::StrongMemoize
  include Importable
  include IssueResourceEvent
  include WorkItemResourceEvent

  self.abstract_class = true

  validates :user, presence: { unless: :importing? }, on: :create

  belongs_to :user

  scope :created_after, ->(time) { where('created_at > ?', time) }

  def discussion_id
    strong_memoize(:discussion_id) do
      Digest::SHA1.hexdigest(discussion_id_key.join("-"))
    end
  end

  def issuable
    raise NoMethodError, "`#{self.class.name}#issuable` method must be implemented"
  end

  private

  def discussion_id_key
    [self.class.name, id, user_id]
  end

  def issuable_id_attrs
    self.class.issuable_attrs.map { |attr| :"#{attr}_id" }
  end
end
