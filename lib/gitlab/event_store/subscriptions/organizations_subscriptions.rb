# frozen_string_literal: true

module Gitlab
  module EventStore
    module Subscriptions
      class OrganizationsSubscriptions < BaseSubscriptions
        def register
          store.subscribe ::Organizations::ActivateWorker, to: ::Organizations::ConfirmedEvent
        end
      end
    end
  end
end
