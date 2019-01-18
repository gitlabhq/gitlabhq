# frozen_string_literal: true

module Clusters
  module Concerns
    module ApplicationStatus
      extend ActiveSupport::Concern

      included do
        scope :installed, -> { where(status: self.state_machines[:status].states[:installed].value) }

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

          event :make_scheduled do
            transition [:installable, :errored] => :scheduled
          end

          event :make_installing do
            transition [:scheduled] => :installing
          end

          event :make_installed do
            transition [:installing] => :installed
          end

          event :make_errored do
            transition any => :errored
          end

          event :make_updating do
            transition [:installed, :updated, :update_errored] => :updating
          end

          event :make_updated do
            transition [:updating] => :updated
          end

          event :make_update_errored do
            transition any => :update_errored
          end

          before_transition any => [:scheduled] do |app_status, _|
            app_status.status_reason = nil
          end

          before_transition any => [:errored] do |app_status, transition|
            status_reason = transition.args.first
            app_status.status_reason = status_reason if status_reason
          end

          before_transition any => [:updating] do |app_status, _|
            app_status.status_reason = nil
          end

          before_transition any => [:update_errored] do |app_status, transition|
            status_reason = transition.args.first
            app_status.status_reason = status_reason if status_reason
          end

          before_transition any => [:installed, :updated] do |app_status, _|
            # When installing any application we are also performing an update
            # of tiller (see Gitlab::Kubernetes::Helm::ClientCommand) so
            # therefore we need to reflect that in the database.
            app_status.cluster.application_helm.update!(version: Gitlab::Kubernetes::Helm::HELM_VERSION)
          end
        end
      end

      def available?
        installed? || updated?
      end

      def update_in_progress?
        updating?
      end
    end
  end
end
