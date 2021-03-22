# frozen_string_literal: true

module Users
  class InProductMarketingEmail < ApplicationRecord
    include BulkInsertSafe

    belongs_to :user

    validates :user, presence: true
    validates :track, presence: true
    validates :series, presence: true
    validates :user_id, uniqueness: {
      scope: [:track, :series],
      message: 'has already been sent'
    }

    enum track: {
      create: 0,
      verify: 1,
      trial: 2,
      team: 3
    }, _suffix: true

    scope :without_track_or_series, -> (track, series) do
      where.not(track: track).or(where.not(series: series))
    end
  end
end
