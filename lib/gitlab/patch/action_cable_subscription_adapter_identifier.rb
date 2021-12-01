# frozen_string_literal: true

# Modifies https://github.com/rails/rails/blob/v6.1.4.1/actioncable/lib/action_cable/subscription_adapter/base.rb so
# that we do not overwrite an id that was explicitly set to `nil` in cable.yml.
# This is needed to support GCP Memorystore. See https://github.com/rails/rails/issues/38244.

module Gitlab
  module Patch
    module ActionCableSubscriptionAdapterIdentifier
      def identifier
        @server.config.cable.has_key?(:id) ? @server.config.cable[:id] : super # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end
    end
  end
end
