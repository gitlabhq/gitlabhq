# == Sortable concern
#
# Set default scope for ordering objects
#
module Sortable
  extend ActiveSupport::Concern

  included do
    scope :order_id_desc, -> { reorder(id: :desc) }
    scope :order_id_asc, -> { reorder(id: :asc) }
    scope :order_created_desc, -> { reorder(created_at: :desc) }
    scope :order_created_asc, -> { reorder(created_at: :asc) }
    scope :order_updated_desc, -> { reorder(updated_at: :desc) }
    scope :order_updated_asc, -> { reorder(updated_at: :asc) }
    scope :order_name_asc, -> { reorder(name: :asc) }
    scope :order_name_desc, -> { reorder(name: :desc) }
  end

  module ClassMethods
    def order_by(method)
      case method.to_s
      when 'created_asc'  then order_created_asc
      when 'created_date' then order_created_desc
      when 'created_desc' then order_created_desc
      when 'id_asc'       then order_id_asc
      when 'id_desc'      then order_id_desc
      when 'name_asc'     then order_name_asc
      when 'name_desc'    then order_name_desc
      when 'updated_asc'  then order_updated_asc
      when 'updated_desc' then order_updated_desc
      else
        all
      end
    end

    private

    def highest_label_priority(target_type_column: nil, target_type: nil, target_column:, project_column:, excluded_labels: [])
      query = Label.select(LabelPriority.arel_table[:priority].minimum)
        .left_join_priorities
        .joins(:label_links)
        .where("label_priorities.project_id = #{project_column}")
        .where("label_links.target_id = #{target_column}")
        .reorder(nil)

      query =
        if target_type_column
          query.where("label_links.target_type = #{target_type_column}")
        else
          query.where(label_links: { target_type: target_type })
        end

      query = query.where.not(title: excluded_labels) if excluded_labels.present?

      query
    end
  end
end
