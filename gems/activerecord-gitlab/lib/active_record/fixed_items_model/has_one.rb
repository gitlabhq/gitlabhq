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

          define_association_getter(association_name, fixed_items_class, foreign_key)
          define_association_setter(association_name, foreign_key)
          define_association_query(association_name, foreign_key)
          define_reset_override
        end

        private

        def define_association_getter(association_name, fixed_items_class, foreign_key)
          define_method(association_name) do
            raise "Missing attribute #{foreign_key}" unless attribute_names.include?(foreign_key)

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
        end

        def define_association_setter(association_name, foreign_key)
          define_method(:"#{association_name}=") do |static_object|
            raise "Missing attribute #{foreign_key}" unless attribute_names.include?(foreign_key)

            @cached_static_associations&.delete(association_name)
            write_attribute(foreign_key, static_object&.id)
          end
        end

        def define_association_query(association_name, foreign_key)
          define_method(:"#{association_name}?") do
            raise "Missing attribute #{foreign_key}" unless attribute_names.include?(foreign_key)

            attribute_present?(foreign_key)
          end
        end

        def define_reset_override
          # Override the reset method to clear cached associations.
          #
          # We use prepend to insert this override early in the method lookup chain,
          # ensuring that our cache-clearing logic runs before any existing reset
          # implementation. This approach works correctly regardless of:
          #
          # 1. Module inclusion order - other modules may define reset before or after
          #    this module is included
          # 2. Whether reset is defined in the class itself
          # 3. Whether reset exists at all
          #
          # Using prepend instead of checking method_defined? at class definition time
          # avoids race conditions where reset might be defined by a module that hasn't
          # been included yet when belongs_to_fixed_items is called.
          #
          # We check at runtime whether a reset method exists further up the method chain
          # by examining the superclass. If it exists, we call it; otherwise, we return self
          # to mimic ActiveRecord's reset behavior.
          #
          # Method lookup order with prepend:
          # PrependedModule#reset -> Class#reset -> Module#reset -> ... -> BasicObject
          reset_override = Module.new do
            define_method(:reset) do |*args|
              @cached_static_associations = nil

              # Call super if it exists in the method chain
              begin
                super(*args)
              rescue NoMethodError => e
                # If there's no super method, return self (mimicking ActiveRecord's reset behavior)
                raise unless e.message.include?('super: no superclass method')

                self
              end
            end
          end

          prepend reset_override
        end
      end
    end
  end
end
