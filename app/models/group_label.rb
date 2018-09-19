# frozen_string_literal: true

class GroupLabel < Label
  belongs_to :group

  validates :group, presence: true

  alias_attribute :subject, :group

  def subject_foreign_key
    'group_id'
  end
end
