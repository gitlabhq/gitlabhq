# frozen_string_literal: true

module Gitlab
  module Reflections
    module Relationships
      # Represents a single relationship in the relationship collection between database tables.
      class Relationship
        include ActiveModel::Model
        include ActiveModel::Attributes

        VALID_ASSOCIATION_TYPES = %w[
          has_many has_one belongs_to has_and_belongs_to_many
          has_many_attached has_one_attached
        ].freeze

        # Core table relationship attributes
        # Database table name of the "parent" model (the "one" side or referenced)
        attribute :parent_table, :string
        # Database table name of the "child" model (the "many" side or model with FK)
        attribute :child_table, :string
        # Foreign key column name in the child table that references the parent
        attribute :foreign_key, :string
        # Primary key column name in the parent table
        attribute :primary_key, :string, default: 'id'
        # The cardinality pattern of the database relationship between parent and child tables
        attribute :relationship_type, :string

        # Association metadata
        # Hash with association details from parent model's perspective
        attribute :parent_association
        # Hash with association details from child model's perspective (for belongs_to)
        attribute :child_association

        # Through association attributes
        # Intermediate table name for :through associations (join table or model)
        attribute :through_table, :string
        # Foreign key in the through table that points to the target model
        attribute :through_target_key, :string

        # Polymorphic association attributes
        # Whether this is a polymorphic association
        attribute :polymorphic, :boolean, default: false
        # Column name that stores the model type (e.g., 'commentable_type')
        attribute :polymorphic_type_column, :string
        # Polymorphic interface name (e.g., 'commentable')
        attribute :polymorphic_name, :string
        # Specific model class name for concrete polymorphic relationships
        attribute :polymorphic_type_value, :string

        # ActiveRecord integration flags
        # Whether this is a :through association
        attribute :is_through_association, :boolean, default: false

        validates :foreign_key, presence: true
        validates :parent_table, presence: true, unless: :polymorphic_belongs_to?
        validates :child_table, presence: true, unless: :polymorphic_has_association?
        validate :valid_associations?

        def polymorphic?
          polymorphic
        end

        def polymorphic_belongs_to?
          polymorphic? && relationship_type == 'many_to_one'
        end

        def polymorphic_has_association?
          polymorphic? && relationship_type != 'many_to_one'
        end

        def to_h
          attributes.compact.symbolize_keys
        end

        def to_json(*args)
          to_h.to_json(*args)
        end

        private

        def valid_associations?
          validate_association(:parent_association, parent_association)
          validate_association(:child_association, child_association)
        end

        def validate_association(field, association)
          return if association.nil?

          unless association.is_a?(Hash)
            errors.add(field, 'must be a hash')
            return
          end

          errors.add(field, 'name cannot be blank') if association[:name].blank?
          errors.add(field, 'type cannot be blank') if association[:type].blank?
          errors.add(field, 'type must be valid') unless VALID_ASSOCIATION_TYPES.include?(association[:type])
        end
      end
    end
  end
end
