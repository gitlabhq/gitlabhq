# frozen_string_literal: true

require 'declarative_policy'

DeclarativePolicy.configure do
  named_policy :global, ::GlobalPolicy
end
