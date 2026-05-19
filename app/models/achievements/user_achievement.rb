# frozen_string_literal: true

module Achievements
  class UserAchievement < ApplicationRecord
    include FromUnion
    include SafelyChangeColumnDefault

    belongs_to :achievement, inverse_of: :user_achievements, optional: false
    belongs_to :user, inverse_of: :user_achievements, optional: false

    belongs_to :awarded_by_user,
      class_name: 'User',
      inverse_of: :awarded_user_achievements,
      optional: false
    belongs_to :revoked_by_user,
      class_name: 'User',
      inverse_of: :revoked_user_achievements,
      optional: true

    scope :not_revoked, -> { where(revoked_by_user_id: nil) }
    scope :shown_on_profile, -> { where(show_on_profile: true) }
    scope :hidden_on_profile, -> { where(show_on_profile: false) }
    scope :for_namespaces, ->(namespace_ids) {
      joins(:achievement).where(achievements: { namespace_id: namespace_ids })
    }
    scope :order_by_priority_asc, -> {
      keyset_order = Gitlab::Pagination::Keyset::Order.build([
        Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
          attribute_name: 'priority',
          order_expression: ::Achievements::UserAchievement.arel_table[:priority].asc,
          nullable: :nulls_last
        ),
        Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
          attribute_name: 'id',
          order_expression: ::Achievements::UserAchievement.arel_table[:id].asc,
          nullable: :not_nullable
        )
      ])
      reorder(keyset_order)
    }
    scope :order_by_id_asc, -> { order(id: :asc) }

    columns_changing_default :show_on_profile

    validates :show_on_profile, inclusion: { in: [false, true] }

    def revoked?
      revoked_by_user_id.present?
    end
  end
end
