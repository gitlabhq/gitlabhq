# frozen_string_literal: true

# rubocop:disable Gitlab/ModuleWithInstanceVariables -- instance variables are set for the including controller
module Admin
  module UsersActions
    extend ActiveSupport::Concern

    include RoutableActions
    include SortingHelper

    PAGINATION_WITH_COUNT_LIMIT = 1000

    included do
      feature_category :user_management

      before_action :user, only: [:show]
      before_action :set_shared_view_parameters, only: [:show]
    end

    def index
      return redirect_to admin_cohorts_path if cohorts_tab_available? && safe_params[:tab] == 'cohorts'

      @sort = safe_params[:sort].presence || sort_value_name

      @users = filter_users
      @users = users_from_search_query(@users) if safe_params[:search_query].present?
      @users = users_with_included_associations(@users)
      @users = @users.sort_by_attribute(@sort)
      @users = @users.page(safe_params[:page])
      @users = @users.without_count if paginate_without_count?
    end

    def show; end

    protected

    def paginate_without_count?
      counts = Gitlab::Database::Count.approximate_counts([User])

      counts[User] > self.class::PAGINATION_WITH_COUNT_LIMIT
    end

    def users_with_included_associations(users)
      users.includes(:trusted_with_spam_attribute, :identities) # rubocop: disable CodeReuse/ActiveRecord
    end

    def users_from_search_query(users)
      users.search(safe_params[:search_query], with_private_emails: true, partial_email_search: partial_email_search?)
    end

    # Overridden in EE
    def partial_email_search?
      true
    end

    # The cohorts tab links to the instance-only admin_cohorts_path, so it is
    # not available in the organization admin area. Overridden there.
    def cohorts_tab_available?
      true
    end

    # Impersonation is an instance-only action, so it is never offered in the
    # organization admin area. Overridden there.
    def impersonation_available?
      true
    end

    def user
      @user ||= find_routable!(User, safe_params[:id], request.fullpath)
    end

    def build_canonical_path(user)
      url_for(safe_params.merge(id: user.to_param))
    end

    private

    def set_shared_view_parameters
      return @can_impersonate = false unless impersonation_available?

      @can_impersonate = helpers.can_impersonate_user(user, impersonation_in_progress?)
      unless @can_impersonate
        @impersonation_error_text =
          helpers.impersonation_error_text(user, impersonation_in_progress?)
      end
    end

    def filter_users
      User.filter_items(safe_params[:filter]).order_name_asc
    end

    def safe_params
      params.permit(
        :id,
        :email_id,
        :personal_projects_page,
        :projects_page,
        :groups_page,
        :tab,
        :search_query,
        :sort,
        :page,
        :filter
      )
    end
  end
end
# rubocop:enable Gitlab/ModuleWithInstanceVariables
