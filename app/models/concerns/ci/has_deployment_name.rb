# frozen_string_literal: true

module Ci
  module HasDeploymentName
    extend ActiveSupport::Concern

    def count_user_deployment?
      Feature.enabled?(:job_deployment_count) && deployment_name?
    end

    def deployment_name?
      self.class::DEPLOYMENT_NAMES.any? { |n| name.downcase.include?(n) }
    end
  end
end
