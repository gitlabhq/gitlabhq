# frozen_string_literal: true

class GroupBadge < Badge
  belongs_to :group

  validates :group, presence: true
end
