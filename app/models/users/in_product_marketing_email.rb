# frozen_string_literal: true

module Users
  class InProductMarketingEmail < ApplicationRecord
    include BulkInsertSafe
    include IgnorableColumns

    ignore_column :campaign, remove_with: '16.7', remove_after: '2023-11-15'

    belongs_to :user

    validates :user, presence: true
    validates :track, presence: true
    validates :series, presence: true

    validates :user_id, uniqueness: {
      scope: [:track, :series],
      message: 'track series email has already been sent'
    }, if: -> { track.present? }

    enum track: {
      create: 0,
      verify: 1,
      trial: 2,
      team: 3,
      experience: 4,
      team_short: 5,
      trial_short: 6,
      admin_verify: 7,
      invite_team: 8
    }, _suffix: true

    # Tracks we don't send emails for (e.g. unsuccessful experiment). These
    # are kept since we already have DB records that use the enum value.
    INACTIVE_TRACK_NAMES = %w[invite_team experience].freeze
    ACTIVE_TRACKS = tracks.except(*INACTIVE_TRACK_NAMES)

    scope :for_user_with_track_and_series, ->(user, track, series) do
      where(user: user, track: track, series: series)
    end

    scope :without_track_and_series, ->(track, series) do
      join_condition = for_user.and(for_track_and_series(track, series))
      users_without_records(join_condition)
    end

    def self.users_table
      User.arel_table
    end

    def self.distinct_users_sql
      name = users_table.table_name
      Arel.sql("DISTINCT ON(#{name}.id) #{name}.*")
    end

    def self.users_without_records(condition)
      arel_join = users_table.join(arel_table, Arel::Nodes::OuterJoin).on(condition)
      joins(arel_join.join_sources)
        .where(in_product_marketing_emails: { id: nil })
        .select(distinct_users_sql)
    end

    def self.for_user
      arel_table[:user_id].eq(users_table[:id])
    end

    def self.for_track_and_series(track, series)
      arel_table[:track].eq(ACTIVE_TRACKS[track])
        .and(arel_table[:series]).eq(series)
    end

    def self.save_cta_click(user, track, series)
      email = for_user_with_track_and_series(user, track, series).take

      email.update(cta_clicked_at: Time.zone.now) if email && email.cta_clicked_at.blank?
    end
  end
end
