# frozen_string_literal: true

module WorkItems
  module SavedViews
    class UserSavedView < ApplicationRecord
      include RelativePositioning

      belongs_to :namespace
      belongs_to :user, inverse_of: :user_saved_views
      belongs_to :saved_view, class_name: 'WorkItems::SavedViews::SavedView', inverse_of: :user_saved_views

      before_create :set_initial_position

      validates :saved_view_id, uniqueness: { scope: :user_id }
      scope :in_namespace, ->(namespace) { where(namespace: namespace) }
      scope :for_user, ->(user) { where(user: user) }
      scope :for_saved_view, ->(saved_view) { where(saved_view: saved_view) }

      before_create :set_initial_position

      class << self
        def subscribe(user:, saved_view:)
          user.with_lock do
            namespace = saved_view.namespace
            if UserSavedView.where(user: user, namespace: namespace).count >= user_saved_view_limit(namespace)
              false
            else
              find_or_create_by!(user: user, saved_view: saved_view, namespace: namespace)
              true
            end
          end
        end

        def unsubscribe(user:, saved_view:)
          find_by(user: user, saved_view: saved_view, namespace: saved_view.namespace)&.destroy

          true
        end

        def relative_positioning_query_base(user_saved_view)
          where(namespace: user_saved_view.namespace, user: user_saved_view.user)
        end

        def relative_positioning_parent_column
          :user_id
        end

        # Overridden in EE
        def user_saved_view_limit(_namespace)
          5
        end
      end

      private

      def set_initial_position
        move_to_end if relative_position.nil?
      end
    end
  end
end

WorkItems::SavedViews::UserSavedView.prepend_mod
