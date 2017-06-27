# == Sortable concern
#
# Set default scope for ordering objects
#
module Sortable
  extend ActiveSupport::Concern

  module DropDefaultScopeOnFinders
    # Override these methods to drop the `ORDER BY id DESC` default scope.
    # See http://dba.stackexchange.com/a/110919 for why we do this.
    %i[find find_by find_by!].each do |meth|
      define_method meth do |*args, &block|
        return super(*args, &block) if block

        unordered_relation = unscope(:order)

        # We cannot simply call `meth` on `unscope(:order)`, since that is also
        # an instance of the same relation class this module is included into,
        # which means we'd get infinite recursion.
        # We explicitly use the original implementation to prevent this.
        original_impl = method(__method__).super_method.unbind
        original_impl.bind(unordered_relation).call(*args)
      end
    end
  end

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
    scope :order_name_asc, -> { reorder(name: :asc) }
    scope :order_name_desc, -> { reorder(name: :desc) }

    # All queries (relations) on this model are instances of this `relation_klass`.
    relation_klass = relation_delegate_class(ActiveRecord::Relation)
    relation_klass.prepend DropDefaultScopeOnFinders
  end

  module ClassMethods
    def order_by(method)
      case method.to_s
      when 'name_asc' then order_name_asc
      when 'name_desc' then order_name_desc
      when 'updated_asc' then order_updated_asc
      when 'updated_desc' then order_updated_desc
      when 'created_asc' then order_created_asc
      when 'created_desc' then order_created_desc
      when 'id_desc' then order_id_desc
      when 'id_asc' then order_id_asc
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
