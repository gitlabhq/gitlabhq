# frozen_string_literal: true

class AutoMergeService < BaseService
  include Gitlab::Utils::StrongMemoize

  STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS = 'merge_when_pipeline_succeeds'
  STRATEGIES = [STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS].freeze

  class << self
    def all_strategies_ordered_by_preference
      STRATEGIES
    end

    def get_service_class(strategy)
      return unless all_strategies_ordered_by_preference.include?(strategy)

      "::AutoMerge::#{strategy.camelize}Service".constantize
    end
  end

  def execute(merge_request, strategy = nil)
    strategy ||= preferred_strategy(merge_request)
    service = get_service_instance(merge_request, strategy)

    return :failed unless service&.available_for?(merge_request)

    service.execute(merge_request)
  end

  def update(merge_request)
    return :failed unless merge_request.auto_merge_enabled?

    strategy = merge_request.auto_merge_strategy
    get_service_instance(merge_request, strategy).update(merge_request)
  end

  def process(merge_request)
    return unless merge_request.auto_merge_enabled?

    strategy = merge_request.auto_merge_strategy
    get_service_instance(merge_request, strategy).process(merge_request)
  end

  def cancel(merge_request)
    return error("Can't cancel the automatic merge", 406) unless merge_request.auto_merge_enabled?

    strategy = merge_request.auto_merge_strategy
    get_service_instance(merge_request, strategy).cancel(merge_request)
  end

  def abort(merge_request, reason)
    return error("Can't abort the automatic merge", 406) unless merge_request.auto_merge_enabled?

    strategy = merge_request.auto_merge_strategy
    get_service_instance(merge_request, strategy).abort(merge_request, reason)
  end

  def available_strategies(merge_request)
    self.class.all_strategies_ordered_by_preference.select do |strategy|
      get_service_instance(merge_request, strategy).available_for?(merge_request)
    end
  end

  def preferred_strategy(merge_request)
    available_strategies(merge_request).first
  end

  private

  def get_service_instance(merge_request, strategy)
    strong_memoize("service_instance_#{merge_request.id}_#{strategy}") do
      self.class.get_service_class(strategy)&.new(project, current_user, params)
    end
  end
end

AutoMergeService.prepend_mod_with('AutoMergeService')
