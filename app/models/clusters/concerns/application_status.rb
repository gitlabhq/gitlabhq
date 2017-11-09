module Clusters
  module Concerns
    module ApplicationStatus
      extend ActiveSupport::Concern

      included do
        state_machine :status, initial: :not_installable do
          state :not_installable, value: -2
          state :errored, value: -1
          state :installable, value: 0
          state :scheduled, value: 1
          state :installing, value: 2
          state :installed, value: 3

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

          before_transition any => [:scheduled] do |app_status, _|
            app_status.status_reason = nil
          end

          before_transition any => [:errored] do |app_status, transition|
            status_reason = transition.args.first
            app_status.status_reason = status_reason if status_reason
          end
        end
      end
    end
  end
end
