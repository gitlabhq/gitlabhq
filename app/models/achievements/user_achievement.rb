# frozen_string_literal: true

module Achievements
  class UserAchievement < ApplicationRecord
    include CacheMarkdownField
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

    cache_markdown_field :award_message, pipeline: :plain_markdown

    before_create :sanitize_award_message_html
    before_update :sanitize_award_message_html

    validates :show_on_profile, inclusion: { in: [false, true] }
    validates :award_message, length: { maximum: 200 }

    def skip_project_check?
      true
    end

    def revoked?
      revoked_by_user_id.present?
    end

    private

    def sanitize_award_message_html
      # award_message_html is populated by CacheMarkdownField's before_create/before_update.
      # This callback runs after that, sanitizing the rendered HTML to strip unsafe tags
      # before the record is persisted. The plain_markdown pipeline does not include a
      # sanitization filter, so user-supplied HTML in award_message would otherwise be
      # stored and exposed via the awardMessageHtml GraphQL field unsanitized.
      return unless award_message_html.present?

      self.award_message_html = Sanitize.fragment(award_message_html, Sanitize::Config::BASIC)
    end
  end
end
