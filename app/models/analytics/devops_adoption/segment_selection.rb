# frozen_string_literal: true

class Analytics::DevopsAdoption::SegmentSelection < ApplicationRecord
  ALLOWED_SELECTIONS_PER_SEGMENT = 20

  belongs_to :segment
  belongs_to :project
  belongs_to :group

  validates :segment, presence: true
  validates :project, presence: { unless: :group }
  validates :project_id, uniqueness: { scope: :segment_id, if: :project }
  validates :group, presence: { unless: :project }
  validates :group_id, uniqueness: { scope: :segment_id, if: :group }

  validate :exclusive_project_or_group
  validate :validate_selection_count, on: :create

  private

  def exclusive_project_or_group
    if project.present? && group.present?
      errors.add(:group, s_('DevopsAdoptionSegmentSelection|The selection cannot be configured for a project and for a group at the same time'))
    end
  end

  def validate_selection_count
    return unless segment

    # handle single model creation and bulk creation from accepts_nested_attributes_for
    selections = segment.segment_selections + [self]
    if selections.reject(&:marked_for_destruction?).uniq.size > ALLOWED_SELECTIONS_PER_SEGMENT
      errors.add(:segment, s_('DevopsAdoptionSegmentSelection|The maximum number of selections has been reached'))
    end
  end
end
