class GenericCommitStatus < CommitStatus
  before_validation :set_default_values

  validates :target_url, url: true,
                         length: { maximum: 255 },
                         allow_nil: true

  # GitHub compatible API
  alias_attribute :context, :name

  def set_default_values
    self.context ||= 'default'
    self.stage ||= 'external'
    self.stage_idx ||= 1000000
  end

  def tags
    [:external]
  end

  def detailed_status(current_user)
    Gitlab::Ci::Status::External::Factory
      .new(self, current_user)
      .fabricate!
  end
end
