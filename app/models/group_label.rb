# frozen_string_literal: true

class GroupLabel < Label
  self.allow_legacy_sti_class = true

  belongs_to :group
  belongs_to :parent_container, foreign_key: :group_id, class_name: 'Group'

  validates :group, presence: true

  alias_attribute :subject, :group

  def subject_foreign_key
    'group_id'
  end

  def preloaded_parent_container
    association(:group).loaded? ? group : parent_container
  end
end
