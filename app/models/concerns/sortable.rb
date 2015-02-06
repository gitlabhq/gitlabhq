# == Sortable concern
#
# Set default scope for ordering objects
#
module Sortable
  extend ActiveSupport::Concern

  included do
    # By default all models should be ordered
    # by created_at field starting from newest
    default_scope { order(created_at: :desc, id: :desc) }

    scope :order_name_asc, -> { reorder(name: :asc) }
    scope :order_created_desc, -> { reorder(created_at: :desc, id: :desc) }
    scope :order_created_asc, -> { reorder(created_at: :asc, id: :asc) }
    scope :order_updated_desc, -> { reorder(updated_at: :desc, id: :desc) }
    scope :order_updated_asc, -> { reorder(updated_at: :asc, id: :asc) }
    scope :order_milestone_due_desc, -> { joins(:milestone).reorder('milestones.due_date DESC, milestones.id DESC') }
    scope :order_milestone_due_asc, -> { joins(:milestone).reorder('milestones.due_date ASC, milestones.id ASC') }
  end

  module ClassMethods
    def order_by(method)
      case method.to_s
      when 'name_asc' then order_name_asc
      when 'updated_asc' then order_updated_asc
      when 'updated_desc' then order_updated_desc
      when 'created_asc' then order_created_asc
      when 'created_desc' then order_created_desc
      when 'milestone_due_asc' then order_milestone_due_asc
      when 'milestone_due_desc' then order_milestone_due_desc
      else
        all
      end
    end
  end
end
