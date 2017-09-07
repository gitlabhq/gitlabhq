module EE::Admin::LogsController
  def loggers
    raise NotImplementedError unless defined?(super)

    @loggers ||= super + [
      Gitlab::GeoLogger
    ]
  end
end
