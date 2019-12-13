# frozen_string_literal: true

class AutoMergeService < BaseService
  STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS = 'merge_when_pipeline_succeeds'.freeze
  STRATEGIES = [STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS].freeze

  class << self
    def all_strategies
      STRATEGIES
    end

    def get_service_class(strategy)
      return unless all_strategies.include?(strategy)

      "::AutoMerge::#{strategy.camelize}Service".constantize
    end
  end

  def execute(merge_request, strategy)
    service = get_service_instance(strategy)

    return :failed unless service&.available_for?(merge_request)

    service.execute(merge_request)
  end

  def update(merge_request)
    return :failed unless merge_request.auto_merge_enabled?

    get_service_instance(merge_request.auto_merge_strategy).update(merge_request)
  end

  def process(merge_request)
    return unless merge_request.auto_merge_enabled?

    get_service_instance(merge_request.auto_merge_strategy).process(merge_request)
  end

  def cancel(merge_request)
    return error("Can't cancel the automatic merge", 406) unless merge_request.auto_merge_enabled?

    get_service_instance(merge_request.auto_merge_strategy).cancel(merge_request)
  end

  def available_strategies(merge_request)
    self.class.all_strategies.select do |strategy|
      get_service_instance(strategy).available_for?(merge_request)
    end
  end

  private

  def get_service_instance(strategy)
    self.class.get_service_class(strategy)&.new(project, current_user, params)
  end
end
