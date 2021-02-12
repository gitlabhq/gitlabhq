# frozen_string_literal: true

module Members
  class InviteEmailExperiment < ApplicationExperiment
    exclude { context.actor.created_by.blank? }
    exclude { context.actor.created_by.avatar_url.nil? }

    INVITE_TYPE = 'initial_email'

    def rollout_strategy
      :round_robin
    end

    def variants
      %i[avatar permission_info control]
    end
  end
end
