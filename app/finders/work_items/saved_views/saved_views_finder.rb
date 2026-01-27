# frozen_string_literal: true

module WorkItems
  module SavedViews
    class SavedViewsFinder
      def initialize(user:, namespace:, params: {})
        @user = user
        @namespace = namespace
        @params = params
      end

      def execute
        items = ::WorkItems::SavedViews::SavedView.in_namespace(namespace)
        items = by_visibility(items)
        items = by_id(items)
        items = by_subscription(items)
        items = by_search(items)

        sort(items)
      end

      private

      attr_reader :user, :namespace, :params

      def by_visibility(items)
        items.visible_to(user)
      end

      def by_id(items)
        return items unless params[:id].present?

        items.id_in(params[:id])
      end

      def by_subscription(items)
        return items unless params[:subscribed_only] && user

        items.subscribed_by(user)
      end

      def by_search(items)
        return items unless params[:search].present?

        items.search(params[:search])
      end

      def sort(items)
        items.sort_by_attributes(params[:sort], user: user, scoped_to_subscribed: params[:subscribed_only])
      end
    end
  end
end
