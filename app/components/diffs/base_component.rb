# frozen_string_literal: true

module Diffs
  class BaseComponent < ViewComponent::Base
    # To make converting the partials to components easier,
    # we delegate all missing methods to the helpers,
    # where they probably are.
    delegate_missing_to :helpers
  end
end
