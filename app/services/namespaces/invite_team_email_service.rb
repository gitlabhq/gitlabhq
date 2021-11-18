# frozen_string_literal: true

module Namespaces
  class InviteTeamEmailService
    include Gitlab::Experiment::Dsl

    TRACK = :invite_team
    DELIVERY_DELAY_IN_MINUTES = 20.minutes

    def self.send_email(user, group)
      new(user, group).execute
    end

    def initialize(user, group)
      @group = group
      @user = user
      @sent_email_records = InProductMarketingEmailRecords.new
    end

    def execute
      return unless user.email_opted_in?
      return unless group.root?
      return unless group.setup_for_company

      # Exclude group if users other than the creator have already been
      # added/invited
      return unless group.member_count == 1

      return if email_for_track_sent_to_user?

      experiment(:invite_team_email, group: group) do |e|
        e.candidate do
          send_email(user, group)
          sent_email_records.add(user, track, series)
          sent_email_records.save!
        end

        e.record!
      end
    end

    private

    attr_reader :user, :group, :sent_email_records

    def send_email(user, group)
      NotificationService.new.in_product_marketing(user.id, group.id, track, series)
    end

    def track
      TRACK
    end

    def series
      0
    end

    def email_for_track_sent_to_user?
      Users::InProductMarketingEmail.for_user_with_track_and_series(user, track, series).present?
    end
  end
end
