module Clusters
  module Concerns
    module ApplicationStatus
      extend ActiveSupport::Concern

      included do
        state_machine :status, initial: :installable do
          state :errored, value: -1
          state :installable, value: 0
          state :scheduled, value: 1
          state :installing, value: 2
          state :installed, value: 3

          event :make_installing do
            transition any - [:installing] => :installing
          end

          event :make_installed do
            transition any - [:installed] => :installed
          end

          event :make_errored do
            transition any - [:errored] => :errored
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
