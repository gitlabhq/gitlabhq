module EE::Admin::LogsController
  include ::Gitlab::Utils::StrongMemoize

  def loggers
    raise NotImplementedError unless defined?(super)

    strong_memoize(:loggers) do
      super + [
        Gitlab::GeoLogger
      ]
    end
  end
end
