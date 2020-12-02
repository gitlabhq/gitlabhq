# frozen_string_literal: true

module TimeZoneHelper
  def timezone_data
    ActiveSupport::TimeZone.all.map do |timezone|
      {
        identifier: timezone.tzinfo.identifier,
        name: timezone.name,
        abbr: timezone.tzinfo.strftime('%Z'),
        offset: timezone.now.utc_offset,
        formatted_offset: timezone.now.formatted_offset
      }
    end
  end
end
