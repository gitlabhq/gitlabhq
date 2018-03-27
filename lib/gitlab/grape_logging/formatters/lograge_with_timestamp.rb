module Gitlab
  module GrapeLogging
    module Formatters
      class LogrageWithTimestamp
        def call(severity, datetime, _, data)
          time = data.delete :time
          attributes = {
            time: datetime.utc.iso8601(3),
            severity: severity,
            duration: time[:total],
            db: time[:db],
            view: time[:view]
          }.merge(data)
          ::Lograge.formatter.call(attributes) + "\n"
        end
      end
    end
  end
end
