class GroupLabel < Label
  belongs_to :group

  validates :group, presence: true
end
