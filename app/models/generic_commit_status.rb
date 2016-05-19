class GenericCommitStatus < CommitStatus
  before_validation :set_default_values

  # GitHub compatible API
  alias_attribute :context, :name

  def set_default_values
    self.context ||= 'default'
    self.stage ||= 'external'
  end

  def tags
    [:external]
  end
end
