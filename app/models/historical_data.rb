class HistoricalData < ActiveRecord::Base
  validates :date, presence: true

  # HistoricalData.during((Date.today - 1.year)..Date.today).average(:active_user_count)
  scope :during, ->(range) { where(date: range) }
  # HistoricalData.up_until(Date.today - 1.month).average(:active_user_count)
  scope :up_until, ->(date) { where("date <= :date", date: date) }

  class << self
    def track!
      create!(
        date:               Date.today,
        active_user_count:  User.active.count
      )
    end

    # HistoricalData.at(Date.new(2014, 1, 1)).active_user_count
    def at(date)
      find_by(date: date)
    end
  end
end
