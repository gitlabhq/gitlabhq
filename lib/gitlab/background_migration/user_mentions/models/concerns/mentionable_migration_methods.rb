# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module UserMentions
      module Models
        module Concerns
          # Extract common no_quote_columns method used in determining the columns that do not need
          # to be quoted for corresponding models
          module MentionableMigrationMethods
            extend ::ActiveSupport::Concern

            class_methods do
              def no_quote_columns
                [
                  :note_id,
                  user_mention_model.resource_foreign_key
                ]
              end
            end
          end
        end
      end
    end
  end
end
