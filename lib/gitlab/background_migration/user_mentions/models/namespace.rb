# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module UserMentions
      module Models
        # isolated Namespace model
        class Namespace < ApplicationRecord
          include ::Gitlab::VisibilityLevel
          include ::Gitlab::Utils::StrongMemoize
          include Gitlab::BackgroundMigration::UserMentions::Models::Concerns::Namespace::RecursiveTraversal

          belongs_to :parent, class_name: "::Gitlab::BackgroundMigration::UserMentions::Models::Namespace"

          def visibility_level_field
            :visibility_level
          end

          def has_parent?
            parent_id.present? || parent.present?
          end

          # Overridden in EE::Namespace
          def feature_available?(_feature)
            false
          end
        end
      end
    end
  end
end

Namespace.prepend_if_ee('::EE::Namespace')
