# frozen_string_literal: true

module Gitlab
  module EventStore
    module Subscriptions
      class OrganizationsSubscriptions < BaseSubscriptions
        def register
          store.subscribe ::Organizations::ActivateWorker, to: ::Organizations::ConfirmedEvent
          store.subscribe ::Organizations::ActivationEmailWorker, to: ::Organizations::ActivatedEvent
        end
      end
    end
  end
end
