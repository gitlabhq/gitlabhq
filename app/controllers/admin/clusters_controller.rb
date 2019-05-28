# frozen_string_literal: true

class Admin::ClustersController < Clusters::ClustersController
  include EnforcesAdminAuthentication

  layout 'admin'

  private

  def clusterable
    @clusterable ||= InstanceClusterablePresenter.fabricate(Clusters::Instance.new, current_user: current_user)
  end
end
