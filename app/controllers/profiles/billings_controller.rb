class Profiles::BillingsController < Profiles::ApplicationController
  before_action :verify_namespace_plan_check_enabled

  def index
    @plans_data = FetchSubscriptionPlansService.new(plan: current_user.namespace.actual_plan).execute
  end
end
