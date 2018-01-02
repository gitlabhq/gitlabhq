class ClearNamespaceSharedRunnersMinutesService < BaseService
  def initialize(namespace)
    @namespace = namespace
  end

  def execute
    NamespaceStatistics.where(namespace: @namespace).update_all(
      shared_runners_seconds: 0,
      shared_runners_seconds_last_reset: Time.now
    )
  end
end
