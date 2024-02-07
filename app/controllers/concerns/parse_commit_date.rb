# frozen_string_literal: true

module ParseCommitDate
  extend ActiveSupport::Concern

  def convert_date_to_epoch(date)
    Date.strptime(date, "%Y-%m-%d")&.to_time&.to_i if date
  rescue Date::Error, TypeError
  end
end
