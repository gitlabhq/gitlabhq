# frozen_string_literal: true

# == Sortable concern
#
# Set default scope for ordering objects
#
module Sortable
  extend ActiveSupport::Concern

  included do
    scope :with_order_id_desc, -> { order(self.arel_table['id'].desc) }
    scope :with_order_id_asc, -> { order(self.arel_table['id'].asc) }
    scope :order_id_desc, -> { reorder(self.arel_table['id'].desc) }
    scope :order_id_asc, -> { reorder(self.arel_table['id'].asc) }
    scope :order_created_desc, -> { reorder(self.arel_table['created_at'].desc) }
    scope :order_created_asc, -> { reorder(self.arel_table['created_at'].asc) }
    scope :order_updated_desc, -> { reorder(self.arel_table['updated_at'].desc) }
    scope :order_updated_asc, -> { reorder(self.arel_table['updated_at'].asc) }
    scope :order_name_asc, -> { reorder(Arel::Nodes::Ascending.new(arel_table[:name].lower)) }
    scope :order_name_desc, -> { reorder(Arel::Nodes::Descending.new(arel_table[:name].lower)) }
  end

  class_methods do
    def order_by(method)
      simple_sorts.fetch(method.to_s, -> { all }).call
    end

    def simple_sorts
      {
        'created_asc' => -> { order_created_asc },
        'created_at_asc' => -> { order_created_asc },
        'created_date' => -> { order_created_desc },
        'created_desc' => -> { order_created_desc },
        'created_at_desc' => -> { order_created_desc },
        'id_asc' => -> { order_id_asc },
        'id_desc' => -> { order_id_desc },
        'name_asc' => -> { order_name_asc },
        'name_desc' => -> { order_name_desc },
        'updated_asc' => -> { order_updated_asc },
        'updated_at_asc' => -> { order_updated_asc },
        'updated_desc' => -> { order_updated_desc },
        'updated_at_desc' => -> { order_updated_desc }
      }
    end

    def build_keyset_order_on_joined_column(scope:, attribute_name:, column:, direction:, nullable:)
      reversed_direction = direction == :asc ? :desc : :asc

      # rubocop: disable GitlabSecurity/PublicSend
      order = ::Gitlab::Pagination::Keyset::Order.build(
        [
          ::Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: attribute_name,
            column_expression: column,
            order_expression: column.send(direction).send(nullable),
            reversed_order_expression: column.send(reversed_direction).send(nullable),
            order_direction: direction,
            add_to_projections: true,
            nullable: nullable
          ),
          ::Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'id',
            order_expression: arel_table['id'].desc
          )
        ]
      )
      # rubocop: enable GitlabSecurity/PublicSend

      order.apply_cursor_conditions(scope).reorder(order)
    end

    private

    def highest_label_priority(target_column:, project_column:, target_type_column: nil, target_type: nil, excluded_labels: [])
      query = Label.select(LabelPriority.arel_table[:priority].minimum.as('label_priority'))
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
