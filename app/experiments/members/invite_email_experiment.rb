# frozen_string_literal: true

module Members
  class InviteEmailExperiment < ApplicationExperiment
    exclude { context.actor.created_by.blank? }
    exclude { context.actor.created_by.avatar_url.nil? }

    INVITE_TYPE = 'initial_email'

    private

    def resolve_variant_name
      # we are overriding here so that when we add another experiment
      # we can merely add that variant and check of feature flag here
      if Feature.enabled?(feature_flag_name, self, type: :experiment, default_enabled: :yaml)
        :avatar
      else
        nil # :control
      end
    end
  end
end
