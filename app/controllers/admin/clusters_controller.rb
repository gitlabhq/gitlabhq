# frozen_string_literal: true

class Admin::ClustersController < ::Clusters::ClustersController
  include EnforcesAdminAuthentication

  before_action :ensure_feature_enabled!

  layout 'admin'

  private

  def clusterable
    @clusterable ||= InstanceClusterablePresenter.fabricate(Clusters::Instance.new, current_user: current_user)
  end
end
