# frozen_string_literal: true

class GroupBadge < Badge
  include EachBatch

  self.allow_legacy_sti_class = true

  belongs_to :group

  validates :group, presence: true
end
