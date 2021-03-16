# frozen_string_literal: true

module Members
  class InviteEmailExperiment < ApplicationExperiment
    exclude { context.actor.created_by.blank? }
    exclude { context.actor.created_by.avatar_url.nil? }

    INVITE_TYPE = 'initial_email'

    def resolve_variant_name
      Strategy::RoundRobin.new(feature_flag_name, %i[avatar permission_info control]).execute
    end
  end
end
