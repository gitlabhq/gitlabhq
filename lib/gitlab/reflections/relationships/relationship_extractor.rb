# frozen_string_literal: true

module Gitlab
  module Reflections
    module Relationships
      class RelationshipExtractor
        SUPPORTED_ASSOCIATION_TYPES = [
          :belongs_to,
          :has_many,
          :has_one,
          :has_and_belongs_to_many,
          :has_many_attached,
          :has_one_attached
        ].freeze

        # Returns relationship data
        def extract
          models_reflection = Gitlab::Reflections::Models::ActiveRecord.instance
          source_data = models_reflection.models
          map_to_relationships(source_data)
        end

        private

        # Processes ActiveRecord models and their reflections to build Relationship objects.
        # Iterates through each model's associations and delegates to appropriate handlers based on association type.
        def map_to_relationships(models)
          relationships = []

          models.each do |model|
            model.reflections.each do |name, reflection|
              next unless SUPPORTED_ASSOCIATION_TYPES.include?(reflection.macro)

              handler_class = determine_handler_class(reflection)
              next unless handler_class

              handler = handler_class.new(model, name, reflection)
              relationships.concat(handler.build_relationships)
            end
          end

          relationships
        end

        def determine_handler_class(reflection)
          if reflection.polymorphic?
            if reflection.macro == :belongs_to
              Handlers::PolymorphicBelongsToHandler
            elsif [:has_many, :has_one].include?(reflection.macro) && reflection.options[:as]
              Handlers::PolymorphicHasAssociationHandler
            end
          else
            case reflection.macro
            when :belongs_to
              Handlers::BelongsToHandler
            when :has_many, :has_one
              # Distinguish between through and direct has associations
              if reflection.through_reflection?
                Handlers::ThroughAssociationHandler
              else
                Handlers::HasAssociationHandler
              end
            when :has_and_belongs_to_many
              Handlers::HabtmHandler
            when :has_many_attached, :has_one_attached
              Handlers::ActiveStorageHandler
            else
              raise ArgumentError, "Unsupported reflection macro: #{reflection.macro}"
            end
          end
        end
      end
    end
  end
end
