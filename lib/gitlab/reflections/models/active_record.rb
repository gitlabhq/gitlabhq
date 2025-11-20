# frozen_string_literal: true

module Gitlab
  module Reflections
    module Models
      # Map GitLab models to tables and back.
      class ActiveRecord
        include Singleton

        # Get the table name for a specific model
        def model_name_to_table_name(model_name)
          model_class = model_name.constantize
          model_class.table_name
        rescue NameError
          nil
        end

        # Get all model names that use a specific table by looking up the db/docs catalog
        def table_name_to_model_names(table_name)
          entry = ::Gitlab::Database::Dictionary.any_entry(table_name)
          return [] unless entry

          entry.classes || []
        end

        def models
          @models ||= begin
            model_classes = []

            ::Gitlab::Database::Dictionary.entries.each do |entry|
              next unless entry.classes

              entry.classes.each do |class_name|
                model_class = class_name.constantize
                model_classes << model_class if included_model?(model_class)
              rescue NameError
                # Skip classes that don't exist (e.g., removed models still referenced in dictionary)
                next
              end
            end

            model_classes.uniq
          end
        end

        private

        def included_model?(model)
          # Only include models that inherit from ApplicationRecord
          model.ancestors.include?(ApplicationRecord)
        end
      end
    end
  end
end
