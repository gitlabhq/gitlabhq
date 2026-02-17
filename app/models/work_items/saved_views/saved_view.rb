# frozen_string_literal: true

module WorkItems
  module SavedViews
    class SavedView < ApplicationRecord
      include Spammable
      include Gitlab::SQL::Pattern

      belongs_to :namespace
      belongs_to :author, foreign_key: :created_by_id, optional: true, inverse_of: :created_saved_views,
        class_name: 'User'

      has_many :user_saved_views, class_name: 'WorkItems::SavedViews::UserSavedView', inverse_of: :saved_view
      has_many :subscribed_users, through: :user_saved_views, source: :user

      scope :in_namespace, ->(namespace) { where(namespace_id: namespace.id) }
      scope :subscribed_by, ->(user) { joins(:user_saved_views).where(user_saved_views: { user_id: user.id }) }
      scope :search, ->(query) { fuzzy_search(query, [:name, :description]) }
      scope :preload_namespace, -> { preload(:namespace) }
      scope :authored_by, ->(user) { where(author: user) }
      scope :private_only, -> { where(private: true) }
      scope :public_only, -> { where(private: false) }
      scope :visible_to, ->(user) { user ? private_only.authored_by(user).or(public_only) : public_only }

      validates :name, presence: true, length: { maximum: 140 }
      validates :description, length: { maximum: 140 }, allow_blank: true
      validates :version, presence: true, numericality: { greater_than: 0 }
      validates :private, inclusion: { in: [true, false] }

      validates :filter_data, json_schema: { filename: "saved_view_filters", size_limit: 8.kilobytes }
      validates :display_settings,
        json_schema: { filename: 'work_item_user_preference_display_settings', size_limit: 8.kilobytes }

      attr_spammable :name, spam_title: true
      attr_spammable :description, spam_description: true

      enum :sort, ::WorkItems::SortingKeys.all.keys

      def self.sort_by_attributes(attribute, user: nil, scoped_to_subscribed: false)
        case attribute
        when :relative_position
          return order_relative_position(user) if user && scoped_to_subscribed
        end

        order(id: :desc)
      end

      def self.order_relative_position(user)
        relation = joins(:user_saved_views)
                     .where(user_saved_views: { user_id: user.id })
                     .order(Arel.sql('user_saved_views.relative_position ASC NULLS LAST'), id: :desc)

        relation.reorder(Gitlab::Pagination::Keyset::Order.build([column_order_relative_position,
          column_order_id_desc]))
      end

      def self.column_order_relative_position
        Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
          attribute_name: 'user_saved_views.relative_position',
          column_expression: UserSavedView.arel_table[:relative_position],
          order_expression: UserSavedView.arel_table[:relative_position].asc.nulls_last,
          nullable: :nulls_last
        )
      end

      def self.column_order_id_desc
        Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
          attribute_name: 'id',
          order_expression: SavedView.arel_table[:id].desc
        )
      end

      # Limit spam checks to public saved views in public namespaces
      def allow_possible_spam?(*)
        return true if Gitlab::CurrentSettings.allow_possible_spam
        return true if private?

        !namespace.public?
      end

      def unsubscribe_other_users!(user:)
        user_saved_views.where.not(user: user).delete_all
      end
    end
  end
end
