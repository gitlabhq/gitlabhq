# frozen_string_literal: true

class Admin::Clusters::ApplicationsController < Clusters::ApplicationsController
  include EnforcesAdminAuthentication

  private

  def clusterable
    @clusterable ||= InstanceClusterablePresenter.fabricate(Clusters::Instance.new, current_user: current_user)
  end
end
