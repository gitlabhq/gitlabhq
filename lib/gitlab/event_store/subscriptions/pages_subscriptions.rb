# frozen_string_literal: true

module Gitlab
  module EventStore
    module Subscriptions
      class PagesSubscriptions < BaseSubscriptions
        def register
          store.subscribe ::Pages::DeletePagesDeploymentWorker, to: ::Projects::ProjectArchivedEvent
          store.subscribe ::Pages::DeleteGroupPagesDeploymentsWorker, to: ::Namespaces::Groups::GroupArchivedEvent
          store.subscribe ::Pages::ResetPagesDefaultDomainRedirectWorker, to: ::Pages::Domains::PagesDomainDeletedEvent
        end
      end
    end
  end
end
