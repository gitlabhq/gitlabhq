# frozen_string_literal: true

class Admin::DashboardController < Admin::ApplicationController
  include CountHelper

  helper Admin::ComponentsHelper

  COUNTED_ITEMS = [Project, User, Group].freeze

  feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned

  def index
    @counts = Gitlab::Database::Count.approximate_counts(COUNTED_ITEMS)
    @projects = Project.order_id_desc.without_deleted.with_route.limit(10)
    @users = User.order_id_desc.limit(10)
    @groups = Group.order_id_desc.with_route.limit(10)
    @notices = Gitlab::ConfigChecker::ExternalDatabaseChecker.check
    @kas_server_info = Gitlab::Kas::ServerInfo.new.present if Gitlab::Kas.enabled?
    @redis_versions = Gitlab::Redis::ALL_CLASSES.map(&:version).uniq
  end

  def stats
    @users_statistics = UsersStatistics.latest
  end
end

Admin::DashboardController.prepend_mod_with('Admin::DashboardController')
