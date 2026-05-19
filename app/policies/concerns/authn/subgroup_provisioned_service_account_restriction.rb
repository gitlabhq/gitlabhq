# frozen_string_literal: true

module Authn
  module SubgroupProvisionedServiceAccountRestriction
    extend ActiveSupport::Concern

    included do
      condition(:sa_provisioned_by_subgroup_or_project, scope: :user) do
        @user&.sa_provisioned_by_subgroup? || @user&.sa_provisioned_by_project?
      end

      rule { sa_provisioned_by_subgroup_or_project }.policy do
        prevent :create_group
        prevent :create_service_account
      end
    end
  end
end
