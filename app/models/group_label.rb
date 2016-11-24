class GroupLabel < Label
  belongs_to :group

  validates :group, presence: true

  alias_attribute :subject, :group

  def subject_foreign_key
    'group_id'
  end

  def to_reference(source_project = nil, target_project = nil, format: :id)
    super(source_project, target_project, format: format)
  end
end
