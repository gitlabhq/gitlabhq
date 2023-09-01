# frozen_string_literal: true

module Namespaces
  class InProductMarketingEmailsService
    TRACKS = {
      create: {
        interval_days: [1, 5, 10],
        completed_actions: [:created],
        incomplete_actions: [:git_write]
      },
      team_short: {
        interval_days: [1],
        completed_actions: [:git_write],
        incomplete_actions: [:user_added]
      },
      trial_short: {
        interval_days: [2],
        completed_actions: [:git_write],
        incomplete_actions: [:trial_started]
      },
      admin_verify: {
        interval_days: [3],
        completed_actions: [:git_write],
        incomplete_actions: [:pipeline_created]
      },
      verify: {
        interval_days: [4, 8, 13],
        completed_actions: [:git_write],
        incomplete_actions: [:pipeline_created]
      },
      trial: {
        interval_days: [1, 5, 10],
        completed_actions: [:git_write, :pipeline_created],
        incomplete_actions: [:trial_started]
      },
      team: {
        interval_days: [1, 5, 10],
        completed_actions: [:git_write, :pipeline_created, :trial_started],
        incomplete_actions: [:user_added]
      }
    }.freeze

    def self.email_count_for_track(track)
      interval_days = TRACKS.dig(track.to_sym, :interval_days)
      interval_days&.count || 0
    end
  end
end

Namespaces::InProductMarketingEmailsService.prepend_mod
