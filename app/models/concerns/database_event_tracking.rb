# frozen_string_literal: true

module DatabaseEventTracking
  extend ActiveSupport::Concern

  included do
    after_create_commit :publish_database_create_event
    after_destroy_commit :publish_database_destroy_event
    after_update_commit :publish_database_update_event
  end

  def publish_database_create_event
    publish_database_event('create')
  end

  def publish_database_destroy_event
    publish_database_event('destroy')
  end

  def publish_database_update_event
    publish_database_event('update')
  end

  def publish_database_event(name)
    # Gitlab::Tracking#event is triggering Snowplow event
    # Snowplow events are sent with usage of
    # https://snowplow.github.io/snowplow-ruby-tracker/SnowplowTracker/AsyncEmitter.html
    # that reports data asynchronously and does not impact performance nor carries a risk of
    # rollback in case of error

    Gitlab::Tracking.database_event(
      self.class.to_s,
      "database_event_#{name}",
      label: self.class.table_name,
      project: try(:project),
      namespace: (try(:group) || try(:namespace)) || try(:project)&.namespace,
      property: name,
      **filtered_record_attributes
    )
  rescue StandardError => err
    # this rescue should be a dead code due to utilization of AsyncEmitter, however
    # since this concern is expected to be included in every model, it is better to
    # prevent against any unexpected outcome
    Gitlab::ErrorTracking.track_and_raise_for_dev_exception(err)
  end

  def filtered_record_attributes
    attributes
      .with_indifferent_access
      .slice(*self.class::SNOWPLOW_ATTRIBUTES)
  end
end
