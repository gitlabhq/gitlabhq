# frozen_string_literal: true

module Ci
  module NamespaceSettings
    class UpdateService
      def initialize(settings, args)
        @settings = settings
        @args = args
      end

      def execute
        return ServiceResponse.success if settings.update(args)

        ServiceResponse.error(message: settings.errors.full_messages)
      rescue ArgumentError => e
        ServiceResponse.error(message: [e.message])
      end

      private

      attr_accessor :args, :settings
    end
  end
end
