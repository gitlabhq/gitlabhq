# frozen_string_literal: true

module Gitlab
  module View
    module Presenter
      class Delegated < SimpleDelegator
        extend ::Gitlab::Utils::DelegatorOverride

        # TODO: Stop including auxiliary methods/modules in `Presenter::Base` as
        # it overrides many methods in the Active Record models.
        # See https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/presenters/README.md#validate-accidental-overrides
        # for more information.
        include Gitlab::View::Presenter::Base

        delegator_override_with Gitlab::Routing.url_helpers
        delegator_override :can?
        delegator_override :can_all?
        delegator_override :can_any?
        delegator_override :declarative_policy_delegate
        delegator_override :present
        delegator_override :web_url

        def initialize(subject, **attributes)
          @subject = subject

          attributes.each do |key, value|
            if subject.respond_to?(key)
              raise CannotOverrideMethodError, "#{subject} already respond to #{key}!"
            end

            define_singleton_method(key) { value }
          end

          super(subject)
        end
      end
    end
  end
end
