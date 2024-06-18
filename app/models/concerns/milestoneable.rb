# frozen_string_literal: true

# == Milestoneable concern
#
# Contains functionality related to objects that can be assigned Milestones
#
# Used by Issuable
#
module Milestoneable
  extend ActiveSupport::Concern

  class_methods do
    def milestone_releases_subquery
      Milestone.joins(:releases).where("#{table_name}.milestone_id = milestones.id")
    end
  end

  included do
    belongs_to :milestone

    validate :milestone_is_valid

    scope :any_milestone, -> { where.not(milestone_id: nil) }
    scope :with_milestone, ->(title) { left_joins_milestones.where(milestones: { title: title }) }
    scope :without_particular_milestones, ->(titles) { left_outer_joins(:milestone).where("milestones.title NOT IN (?) OR milestone_id IS NULL", titles) }
    scope :any_release, -> do
      where("EXISTS (?)", milestone_releases_subquery)
    end
    scope :with_release, ->(tag, project_id) do
      where("EXISTS (?)", milestone_releases_subquery.where(releases: { tag: tag, project_id: project_id }))
    end
    scope :without_particular_release, ->(tag, project_id) do
      where("EXISTS (?)", milestone_releases_subquery.where.not(releases: { tag: tag, project_id: project_id }))
    end

    scope :left_joins_milestones,    -> { joins("LEFT OUTER JOIN milestones ON #{table_name}.milestone_id = milestones.id") }
    scope :order_milestone_due_desc, -> { left_joins_milestones.reorder(Arel.sql('milestones.due_date IS NULL, milestones.id IS NULL, milestones.due_date DESC')) }
    scope :order_milestone_due_asc,  -> { left_joins_milestones.reorder(Arel.sql('milestones.due_date IS NULL, milestones.id IS NULL, milestones.due_date ASC')) }

    scope :without_release, -> do
      joins("LEFT OUTER JOIN milestone_releases ON #{table_name}.milestone_id = milestone_releases.milestone_id")
        .where(milestone_releases: { release_id: nil })
    end

    scope :milestone_id_in, ->(ids) { where(milestone_id: ids) }

    private

    def milestone_is_valid
      errors.add(:milestone_id, 'is invalid') if respond_to?(:milestone_id) && !milestone_available?
    end
  end

  def milestone_available?
    return true if milestone_id.blank?

    (project_id.present? && project_id == milestone&.project_id) ||
      try(:namespace)&.self_and_ancestors&.include?(milestone&.group) ||
      project&.ancestors_upto&.compact&.include?(milestone&.group)
  end

  ##
  # Overridden on EE module
  #
  def supports_milestone?
    respond_to?(:milestone_id)
  end
end

Milestoneable.prepend_mod_with('Milestoneable')
