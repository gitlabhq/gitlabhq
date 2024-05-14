# frozen_string_literal: true

module Pages
  class DeploymentPolicy < BasePolicy
    delegate { @subject.project }

    rule { can?(:update_pages) }.policy do
      enable :read_pages_deployments
      enable :update_pages_deployments
    end
  end
end

Pages::DeploymentPolicy.prepend_mod_with('DeploymentPolicy')
