module Geo
  # Base class for event store classes.
  #
  # Each store should also specify its event type by calling
  # `self.event_type = ...` in the body of the class. The value of
  # this method should be a symbol such as `:repository_updated_event`
  # or `:repository_deleted_event`. For example:
  #
  #     class RepositoryUpdatedEventStore < EventStore
  #       self.event_type = :repository_updated_event
  #     end
  #
  # The event type is used to determine which attribute we should set
  # on an instance of the Geo::EventLog class.
  #
  # Event store classes should implement the instance method `build_event`.
  # The `build_event` method is supposed to return an instance of the event
  # that will be logged.
  class EventStore
    class << self
      attr_accessor :event_type
    end

    attr_reader :project, :params

    def initialize(project, params = {})
      @project = project
      @params  = params
    end

    def create
      return unless Gitlab::Geo.primary?

      Geo::EventLog.create!("#{self.class.event_type}" => build_event)
    rescue ActiveRecord::RecordInvalid, NoMethodError => e
      log_error("#{self.event_type.to_s.humanize} could not be created", e)
    end

    private

    def build_event
      raise NotImplementedError,
        "#{self.class} does not implement #{__method__}"
    end

    def log_error(message, error)
      Gitlab::Geo::Logger.error(
        class: self.class.name,
        message: message,
        error: error,
        project_id: project.id,
        project_path: project.path_with_namespace)
    end
  end
end
