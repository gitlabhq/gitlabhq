module PipelineSchedulesHelper
  def timezone_data
    ActiveSupport::TimeZone.all.map do |timezone|
      {
        name: timezone.name,
        offset: timezone.now.utc_offset,
        identifier: timezone.tzinfo.identifier
      }
    end
  end
end
