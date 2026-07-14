# frozen_string_literal: true

# Canary experiment used to verify the experimentation pipeline end to end.
#
# The experiments API (ee/lib/api/experiments.rb) invokes this experiment as a
# canary to confirm experimentation is working. With strict registration
# enabled, every experiment name must resolve to a registered class, so this
# class exists to register the `null_hypothesis` name and its variants.
class NullHypothesisExperiment < ApplicationExperiment
  def self.context_keys = %i[user]

  control { nil }
  candidate { nil }
end
