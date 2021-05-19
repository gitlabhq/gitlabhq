# frozen_string_literal: true

# == Milestoneable concern
#
# Contains functionality related to objects that can be assigned Milestones
#
# Used by Issuable
#
module Milestoneable
  extend ActiveSupport::Concern

  included do
    belongs_to :milestone

    validate :milestone_is_valid

    scope :of_milestones, ->(ids) { where(milestone_id: ids) }
    scope :any_milestone, -> { where.not(milestone_id: nil) }
    scope :with_milestone, ->(title) { left_joins_milestones.where(milestones: { title: title }) }
    scope :without_particular_milestone, ->(title) { left_outer_joins(:milestone).where("milestones.title != ? OR milestone_id IS NULL", title) }
    scope :any_release, -> { joins_milestone_releases }
    scope :with_release, -> (tag, project_id) { joins_milestone_releases.where( milestones: { releases: { tag: tag, project_id: project_id } } ) }
    scope :without_particular_release, -> (tag, project_id) { joins_milestone_releases.where.not( milestones: { releases: { tag: tag, project_id: project_id } } ) }

    scope :left_joins_milestones,    -> { joins("LEFT OUTER JOIN milestones ON #{table_name}.milestone_id = milestones.id") }
    scope :order_milestone_due_desc, -> { left_joins_milestones.reorder(Arel.sql('milestones.due_date IS NULL, milestones.id IS NULL, milestones.due_date DESC')) }
    scope :order_milestone_due_asc,  -> { left_joins_milestones.reorder(Arel.sql('milestones.due_date IS NULL, milestones.id IS NULL, milestones.due_date ASC')) }

    scope :without_release, -> do
      joins("LEFT OUTER JOIN milestone_releases ON #{table_name}.milestone_id = milestone_releases.milestone_id")
        .where(milestone_releases: { release_id: nil })
    end

    scope :joins_milestone_releases, -> do
      joins("JOIN milestone_releases ON #{table_name}.milestone_id = milestone_releases.milestone_id
             JOIN releases ON milestone_releases.release_id = releases.id").distinct
    end

    private

    def milestone_is_valid
      errors.add(:milestone_id, 'is invalid') if respond_to?(:milestone_id) && !milestone_available?
    end
  end

  def milestone_available?
    return true if milestone_id.blank?

    project_id == milestone&.project_id || project.ancestors_upto.compact.include?(milestone&.group)
  end

  ##
  # Overridden on EE module
  #
  def supports_milestone?
    respond_to?(:milestone_id)
  end
end

Milestoneable.prepend_mod_with('Milestoneable')
