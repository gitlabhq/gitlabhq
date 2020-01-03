# frozen_string_literal: true

module Deployments
  class AfterCreateService
    attr_reader :deployment
    attr_reader :deployable

    delegate :environment, to: :deployment
    delegate :variables, to: :deployable
    delegate :options, to: :deployable, allow_nil: true

    def initialize(deployment)
      @deployment = deployment
      @deployable = deployment.deployable
    end

    def execute
      deployment.create_ref
      deployment.invalidate_cache

      update_environment(deployment)

      deployment
    end

    def update_environment(deployment)
      ActiveRecord::Base.transaction do
        if (url = expanded_environment_url)
          environment.external_url = url
        end

        renew_auto_stop_in
        environment.fire_state_event(action)

        if environment.save && !environment.stopped?
          deployment.update_merge_request_metrics!
        end
      end
    end

    private

    def environment_options
      options&.dig(:environment) || {}
    end

    def expanded_environment_url
      ExpandVariables.expand(environment_url, -> { variables }) if environment_url
    end

    def environment_url
      environment_options[:url]
    end

    def action
      environment_options[:action] || 'start'
    end

    def renew_auto_stop_in
      return unless deployable

      environment.auto_stop_in = deployable.environment_auto_stop_in
    end
  end
end

Deployments::AfterCreateService.prepend_if_ee('EE::Deployments::AfterCreateService')
