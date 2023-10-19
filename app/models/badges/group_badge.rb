# frozen_string_literal: true

class GroupBadge < Badge
  include EachBatch

  belongs_to :group

  validates :group, presence: true
end
