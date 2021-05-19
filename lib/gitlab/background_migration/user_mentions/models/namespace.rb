# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module UserMentions
      module Models
        # isolated Namespace model
        class Namespace < ActiveRecord::Base
          self.inheritance_column = :_type_disabled

          include Concerns::IsolatedFeatureGate
          include Gitlab::BackgroundMigration::UserMentions::Lib::Gitlab::IsolatedVisibilityLevel
          include ::Gitlab::Utils::StrongMemoize
          include Gitlab::BackgroundMigration::UserMentions::Models::Concerns::Namespace::RecursiveTraversal

          belongs_to :parent, class_name: "::Gitlab::BackgroundMigration::UserMentions::Models::Namespace"

          def visibility_level_field
            :visibility_level
          end

          def has_parent?
            parent_id.present? || parent.present?
          end

          # Deprecated, use #licensed_feature_available? instead. Remove once Namespace#feature_available? isn't used anymore.
          def feature_available?(feature)
            licensed_feature_available?(feature)
          end

          # Overridden in EE::Namespace
          def licensed_feature_available?(_feature)
            false
          end
        end
      end
    end
  end
end

Namespace.prepend_mod_with('Namespace')
