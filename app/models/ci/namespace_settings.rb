# frozen_string_literal: true

# CI::NamespaceSettings mixin
#
# This module is intended to encapsulate CI/CD settings-specific logic
# and be prepended in the `Namespace` model
module Ci
  module NamespaceSettings
    # Overridden in EE::Namespace
    def allow_stale_runner_pruning?
      false
    end

    # Overridden in EE::Namespace
    def allow_stale_runner_pruning=(_value)
      raise NotImplementedError
    end
  end
end
