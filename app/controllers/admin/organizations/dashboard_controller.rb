# frozen_string_literal: true

module Admin
  module Organizations
    class DashboardController < Admin::Organizations::ApplicationController
      COUNTED_ITEMS = [Project, User, Group].freeze
      ORGANIZATION_COUNT_SCOPES = { User => :member_of_organization }.freeze

      feature_category :organization

      def index
        organization = ::Current.organization

        @counts = Gitlab::Database::Count.approximate_counts_for_organization(
          COUNTED_ITEMS, organization, scopes: ORGANIZATION_COUNT_SCOPES
        )
        @projects = Project.in_organization(organization).order_id_desc.without_deleted.with_route.limit(10)
        @users = User.member_of_organization(organization).order_id_desc.limit(10)
        @groups = Group.in_organization(organization).order_id_desc.with_route.limit(10)
      end
    end
  end
end
