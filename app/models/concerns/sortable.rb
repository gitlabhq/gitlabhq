# == Sortable concern
#
# Set default scope for ordering objects
#
module Sortable
  extend ActiveSupport::Concern

  included do
    # By default all models should be ordered
    # by created_at field starting from newest
    default_scope { order_id_desc }

    scope :order_id_desc, -> { reorder(id: :desc) }
    scope :order_id_asc, -> { reorder(id: :asc) }
    scope :order_created_desc, -> { reorder(created_at: :desc) }
    scope :order_created_asc, -> { reorder(created_at: :asc) }
    scope :order_updated_desc, -> { reorder(updated_at: :desc) }
    scope :order_updated_asc, -> { reorder(updated_at: :asc) }
    scope :order_name_asc, -> { reorder("LOWER(#{quoted_table_name}.#{connection.quote_column_name('name')}) ASC") }
    scope :order_name_desc, -> { reorder("LOWER(#{quoted_table_name}.#{connection.quote_column_name('name')}) DESC") }
  end

  module ClassMethods
    # Adds a new sort method.
    def sortable_by(sort_name, scope_name)
      sortables[sort_name.to_s] = scope_name
    end

    # Accessor for sort methods marked mentionable.
    def sortables
      @sortables ||= {}
    end

    def order_by(method)
      return all if method.blank?

      method = method.to_s

      case method
      when 'name_asc' then order_name_asc
      when 'name_desc' then order_name_desc
      when 'updated_asc' then order_updated_asc
      when 'updated_desc' then order_updated_desc
      when 'created_asc' then order_created_asc
      when 'created_desc' then order_created_desc
      when 'id_desc' then order_id_desc
      when 'id_asc' then order_id_asc
      else
        if sortables[method].present? && respond_to?(sortables[method])
          send(sortables[method])
        else
          all
        end
      end
    end
  end
end
