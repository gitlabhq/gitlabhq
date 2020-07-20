# frozen_string_literal: true

class ResourceEvent < ApplicationRecord
  include Gitlab::Utils::StrongMemoize
  include Importable

  self.abstract_class = true

  validates :user, presence: { unless: :importing? }, on: :create

  belongs_to :user

  scope :created_after, ->(time) { where('created_at > ?', time) }
  scope :created_on_or_before, ->(time) { where('created_at <= ?', time) }

  def discussion_id
    strong_memoize(:discussion_id) do
      Digest::SHA1.hexdigest(discussion_id_key.join("-"))
    end
  end

  private

  def discussion_id_key
    [self.class.name, id, user_id]
  end

  def exactly_one_issuable
    issuable_count = self.class.issuable_attrs.count { |attr| self["#{attr}_id"] }

    return true if issuable_count == 1

    # if none of issuable IDs is set, check explicitly if nested issuable
    # object is set, this is used during project import
    if issuable_count == 0 && importing?
      issuable_count = self.class.issuable_attrs.count { |attr| self.public_send(attr) } # rubocop:disable GitlabSecurity/PublicSend

      return true if issuable_count == 1
    end

    errors.add(
      :base, _("Exactly one of %{attributes} is required") %
        { attributes: self.class.issuable_attrs.join(', ') }
    )
  end
end
