# frozen_string_literal: true

module Ci
  module DeployablePolicy
    extend ActiveSupport::Concern

    included do
      prepend_mod_with('Ci::DeployablePolicy') # rubocop: disable Cop/InjectEnterpriseEditionModule

      condition(:outdated_deployment) do
        @subject.outdated_deployment?
      end

      rule { outdated_deployment }.prevent :update_build
    end
  end
end
