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
    scope :order_name, -> { reorder(name: :asc) }
    scope :order_recent, -> { reorder(created_at: :desc, id: :desc) }
    scope :order_oldest, -> { reorder(created_at: :asc, id: :asc) }
    scope :order_recent_updated, -> { reorder(updated_at: :desc, id: :desc) }
    scope :order_oldest_updated, -> { reorder(updated_at: :asc, id: :asc) }
  end

  module ClassMethods
    def order_by(method)
      case method.to_s
      when 'name' then order_name_asc
      when 'recent' then order_recent
      when 'oldest' then order_oldest
      when 'recent_updated' then order_recent_updated
      when 'oldest_updated' then order_oldest_updated
      else
        all
      end
    end
  end
end
