# frozen_string_literal: true

module Clusters
  module Concerns
    module ApplicationStatus
      extend ActiveSupport::Concern

      included do
        scope :available, -> do
          where(
            status: [
              self.state_machines[:status].states[:externally_installed].value,
              self.state_machines[:status].states[:installed].value,
              self.state_machines[:status].states[:updated].value
            ]
          )
        end

        state_machine :status, initial: :not_installable do
          state :not_installable, value: -2
          state :errored, value: -1
          state :installable, value: 0
          state :scheduled, value: 1
          state :installing, value: 2
          state :installed, value: 3
          state :updating, value: 4
          state :updated, value: 5
          state :update_errored, value: 6
          state :uninstalling, value: 7
          state :uninstall_errored, value: 8
          state :uninstalled, value: 10
          state :externally_installed, value: 11

          # Used for applications that are pre-installed by the cluster,
          # e.g. Knative in GCP Cloud Run enabled clusters
          # Because we cannot upgrade or uninstall Knative in these clusters,
          # we define only one simple state transition to enter the `pre_installed` state,
          # and no exit transitions.
          state :pre_installed, value: 9

          event :make_externally_installed do
            transition any => :externally_installed
          end

          event :make_externally_uninstalled do
            transition any => :uninstalled
          end

          event :make_scheduled do
            transition [:installable, :errored, :installed, :updated, :update_errored, :uninstall_errored] => :scheduled
          end

          event :make_installing do
            transition [:scheduled] => :installing
          end

          event :make_installed do
            transition [:installing] => :installed
            transition [:updating] => :updated
          end

          event :make_pre_installed do
            transition any => :pre_installed
          end

          event :make_errored do
            transition any - [:updating, :uninstalling] => :errored
            transition [:updating] => :update_errored
            transition [:uninstalling] => :uninstall_errored
          end

          event :make_updating do
            transition [:installed, :updated, :update_errored, :scheduled] => :updating
          end

          event :make_update_errored do
            transition any => :update_errored
          end

          event :make_uninstalling do
            transition [:scheduled] => :uninstalling
          end

          before_transition any => [:scheduled, :installed, :uninstalled, :externally_installed] do |application, _|
            application.status_reason = nil
          end

          before_transition any => [:errored] do |application, transition|
            status_reason = transition.args.first
            application.status_reason = status_reason if status_reason
          end

          before_transition any => [:updating] do |application, _|
            application.status_reason = nil
          end

          before_transition any => [:update_errored, :uninstall_errored] do |application, transition|
            status_reason = transition.args.first
            application.status_reason = status_reason if status_reason
          end

          after_transition any => [:uninstalling], :use_transactions => false do |application, _|
            application.prepare_uninstall
          end
        end
      end

      def status_states
        self.class.state_machines[:status].states.each_with_object({}) do |state, states|
          states[state.name] = state.value
        end
      end

      def updateable?
        installed? || updated? || update_errored?
      end

      def available?
        pre_installed? || installed? || externally_installed? || updated?
      end

      def update_in_progress?
        updating?
      end
    end
  end
end
