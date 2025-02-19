# frozen_string_literal: true

module ActiveRecord
  module FixedItemsModel
    # Realizes a has one association with a fixed items model.
    #
    # See ActiveRecord::FixedItemsModel::Model for reference
    # for such a fixed items model.
    #
    # A minimal example is:
    #
    # class MyModel < ApplicationRecord
    #   include ActiveRecord::FixedItemsModel::HasOne
    #
    #   belongs_to_fixed_items :static_model, fixed_items_class: StaticModel
    # end
    #
    # The attribute `static_model_id` must exist for the model.
    #
    # Usage:
    #
    # m = MyModel.last
    # m.static_model # Returns fixed items model instance
    # m.static_model = StaticModel.find(1)
    # m.static_model_id = 1 # still possible
    # m.static_model? # Bool
    #
    module HasOne
      extend ActiveSupport::Concern

      class_methods do
        def belongs_to_fixed_items(association_name, fixed_items_class:, foreign_key: nil)
          foreign_key ||= "#{association_name}_id"

          raise "Missing attribute #{foreign_key}" unless attribute_names.include?(foreign_key)

          # Getter method
          define_method(association_name) do
            current_id = read_attribute(foreign_key)
            return if current_id.nil?

            @cached_static_associations ||= {}

            cached_association = @cached_static_associations[association_name]

            # Invalidate cache if the foreign key has changed
            if cached_association && cached_association.id != current_id
              @cached_static_associations.delete(association_name)
            end

            @cached_static_associations[association_name] ||= fixed_items_class.find(current_id)
          end

          # Setter method
          define_method(:"#{association_name}=") do |static_object|
            @cached_static_associations&.delete(association_name)
            write_attribute(foreign_key, static_object&.id)
          end

          # Query method
          define_method(:"#{association_name}?") do
            attribute_present?(foreign_key)
          end

          # Clear cache on reset
          if method_defined?(:reset)
            after_reset = instance_method(:reset)
            define_method(:reset) do |*args|
              @cached_static_associations = nil
              after_reset.bind_call(self, *args)
            end
          else
            define_method(:reset) do
              @cached_static_associations = nil
              self
            end
          end
        end
      end
    end
  end
end
