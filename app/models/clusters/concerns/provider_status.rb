# frozen_string_literal: true

module Clusters
  module Concerns
    module ProviderStatus
      extend ActiveSupport::Concern

      included do
        state_machine :status, initial: :scheduled do
          state :scheduled, value: 1
          state :creating, value: 2
          state :created, value: 3
          state :errored, value: 4

          event :make_creating do
            transition any - [:creating] => :creating
          end

          event :make_created do
            transition any - [:created] => :created
          end

          event :make_errored do
            transition any - [:errored] => :errored
          end

          before_transition any => [:errored, :created] do |provider, _|
            provider.nullify_credentials
          end

          before_transition any => [:creating] do |provider, transition|
            operation_id = transition.args.first
            provider.assign_operation_id(operation_id) if operation_id
          end

          before_transition any => [:errored] do |provider, transition|
            status_reason = transition.args.first
            provider.status_reason = status_reason if status_reason
          end
        end

        def on_creation?
          scheduled? || creating?
        end

        def assign_operation_id(_)
          # Implemented by individual providers if operation ID is supported.
        end
      end
    end
  end
end
