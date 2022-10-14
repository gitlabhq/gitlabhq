# frozen_string_literal: true

module Gitlab
  module RequestEndpoints
    class << self
      def all_api_endpoints
        # This compile does not do anything if the routes were already built
        # but if they weren't, the routes will be drawn and available for the rest of
        # application.
        API::API.compile!
        API::API.reset_routes!
        API::API.routes.select { |route| route.app.options[:for] < API::Base }
      end

      def all_controller_actions
        # This will return tuples of all controller actions defined in the routes
        # Only for controllers inheriting ApplicationController
        # Excluding controllers from gems (OAuth, Sidekiq)
        Rails.application.routes.routes.filter_map do |route|
          route_info = route.required_defaults.presence
          next unless route_info
          next if route_info[:controller].blank? || route_info[:action].blank?

          controller = constantize_controller(route_info[:controller])
          next unless controller&.include?(::Gitlab::EndpointAttributes)
          next if controller == ApplicationController
          next if controller == Devise::UnlocksController

          [controller, route_info[:action]]
        end
      end

      private

      def constantize_controller(name)
        "#{name.camelize}Controller".constantize
      rescue NameError
        nil # some controllers, like the omniauth ones are dynamic
      end
    end
  end
end
