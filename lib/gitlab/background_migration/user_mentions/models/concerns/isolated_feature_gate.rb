# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module UserMentions
      module Models
        module Concerns
          # isolated FeatureGate module
          module IsolatedFeatureGate
            def flipper_id
              return if new_record?

              "#{self.class.name}:#{id}"
            end
          end
        end
      end
    end
  end
end
