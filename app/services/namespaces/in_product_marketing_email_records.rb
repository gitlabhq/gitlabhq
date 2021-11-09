# frozen_string_literal: true

module Namespaces
  class InProductMarketingEmailRecords
    attr_reader :records

    def initialize
      @records = []
    end

    def save!
      Users::InProductMarketingEmail.bulk_insert!(@records)
      @records = []
    end

    def add(user, track, series)
      @records << Users::InProductMarketingEmail.new(
        user: user,
        track: track,
        series: series,
        created_at: Time.zone.now,
        updated_at: Time.zone.now
      )
    end
  end
end
