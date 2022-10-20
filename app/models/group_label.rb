# frozen_string_literal: true

class GroupLabel < Label
  belongs_to :group
  belongs_to :parent_container, foreign_key: :group_id, class_name: 'Group'

  validates :group, presence: true

  alias_attribute :subject, :group

  def subject_foreign_key
    'group_id'
  end
end
