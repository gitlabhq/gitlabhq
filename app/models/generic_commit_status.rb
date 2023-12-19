# frozen_string_literal: true

class GenericCommitStatus < CommitStatus
  EXTERNAL_STAGE_IDX = 1_000_000

  self.allow_legacy_sti_class = true

  validates :target_url, addressable_url: true, length: { maximum: 255 }, allow_nil: true
  validate :name_uniqueness_across_types, unless: :importing?

  # GitHub compatible API
  alias_attribute :context, :name

  def tags
    [:external]
  end

  def detailed_status(current_user)
    Gitlab::Ci::Status::External::Factory
      .new(self, current_user)
      .fabricate!
  end

  private

  def name_uniqueness_across_types
    return if !pipeline || name.blank?

    if pipeline.statuses.by_name(name).where.not(type: type).exists?
      errors.add(:name, :taken)
    end
  end
end
