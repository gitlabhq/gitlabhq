# frozen_string_literal: true

module ErrorTracking
  module Collector
    class SentryRequestParser
      def self.parse(request)
        body = request.body.read

        # Request body contains 3 json objects merged together in one StringIO.
        # We need to separate and parse them into array of hash objects.
        json_objects = []
        parser = Yajl::Parser.new

        parser.parse(body) do |json_object|
          json_objects << json_object
        end

        # The request contains 3 objects: sentry metadata, type data and event data.
        # We need only last two. Type to decide what to do with the request.
        # And event data as it contains all information about the exception.
        _, type, event = json_objects

        {
          request_type: type['type'],
          event: event
        }
      end
    end
  end
end
