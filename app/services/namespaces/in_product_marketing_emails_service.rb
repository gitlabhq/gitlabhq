# frozen_string_literal: true

module Namespaces
  class InProductMarketingEmailsService
    include Gitlab::Experimentation::GroupTypes

    INTERVAL_DAYS = [1, 5, 10].freeze
    TRACKS = {
      create: :git_write,
      verify: :pipeline_created,
      trial: :trial_started,
      team: :user_added
    }.freeze

    def self.send_for_all_tracks_and_intervals
      TRACKS.each_key do |track|
        INTERVAL_DAYS.each do |interval|
          new(track, interval).execute
        end
      end
    end

    def initialize(track, interval)
      @track = track
      @interval = interval
      @in_product_marketing_email_records = []
    end

    def execute
      raise ArgumentError, "Track #{track} not defined" unless TRACKS.key?(track)

      groups_for_track.each_batch do |groups|
        groups.each do |group|
          send_email_for_group(group)
        end
      end
    end

    private

    attr_reader :track, :interval, :in_product_marketing_email_records

    def send_email_for_group(group)
      if Gitlab.com?
        experiment_enabled_for_group = experiment_enabled_for_group?(group)
        experiment_add_group(group, experiment_enabled_for_group)
        return unless experiment_enabled_for_group
      end

      users_for_group(group).each do |user|
        if can_perform_action?(user, group)
          send_email(user, group)
          track_sent_email(user, track, series)
        end
      end

      save_tracked_emails!
    end

    def experiment_enabled_for_group?(group)
      Gitlab::Experimentation.in_experiment_group?(:in_product_marketing_emails, subject: group)
    end

    def experiment_add_group(group, experiment_enabled_for_group)
      variant = experiment_enabled_for_group ? GROUP_EXPERIMENTAL : GROUP_CONTROL
      Experiment.add_group(:in_product_marketing_emails, variant: variant, group: group)
    end

    def groups_for_track
      onboarding_progress_scope = OnboardingProgress
        .completed_actions_with_latest_in_range(completed_actions, range)
        .incomplete_actions(incomplete_action)

      # Filtering out sub-groups is a temporary fix to prevent calling
      # `.root_ancestor` on groups that are not root groups.
      # See https://gitlab.com/groups/gitlab-org/-/epics/5594 for more information.
      Group
        .top_most
        .with_onboarding_progress
        .merge(onboarding_progress_scope)
        .merge(subscription_scope)
    end

    def subscription_scope
      {}
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def users_for_group(group)
      group.users
        .where(email_opted_in: true)
        .merge(Users::InProductMarketingEmail.without_track_and_series(track, series))
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def can_perform_action?(user, group)
      case track
      when :create
        user.can?(:create_projects, group)
      when :verify
        user.can?(:create_projects, group)
      when :trial
        user.can?(:start_trial, group)
      when :team
        user.can?(:admin_group_member, group)
      end
    end

    def send_email(user, group)
      NotificationService.new.in_product_marketing(user.id, group.id, track, series)
    end

    def completed_actions
      index = TRACKS.keys.index(track)
      index == 0 ? [:created] : TRACKS.values[0..index - 1]
    end

    def range
      date = (interval + 1).days.ago
      date.beginning_of_day..date.end_of_day
    end

    def incomplete_action
      TRACKS[track]
    end

    def series
      INTERVAL_DAYS.index(interval)
    end

    def save_tracked_emails!
      Users::InProductMarketingEmail.bulk_insert!(in_product_marketing_email_records)
      @in_product_marketing_email_records = []
    end

    def track_sent_email(user, track, series)
      in_product_marketing_email_records << Users::InProductMarketingEmail.new(
        user: user,
        track: track,
        series: series,
        created_at: Time.zone.now,
        updated_at: Time.zone.now
      )
    end
  end
end

Namespaces::InProductMarketingEmailsService.prepend_mod
