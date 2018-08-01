module EE
  module Clusters
    module ApplicationStatus
      extend ActiveSupport::Concern

      prepended do
        state_machine :status, initial: :not_installable do
          state :updating, value: 4
          state :updated, value: 5
          state :update_errored, value: 6

          event :make_updating do
            transition [:installed, :updated, :update_errored] => :updating
          end

          event :make_updated do
            transition [:updating] => :updated
          end

          event :make_update_errored do
            transition any => :update_errored
          end

          before_transition any => [:updating] do |app_status, _|
            app_status.status_reason = nil
          end

          before_transition any => [:update_errored] do |app_status, transition|
            status_reason = transition.args.first
            app_status.status_reason = status_reason if status_reason
          end
        end
      end
    end
  end
end
