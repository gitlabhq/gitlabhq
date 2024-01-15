# frozen_string_literal: true

module TimeZoneHelper
  TIME_ZONE_FORMAT_ATTRS = {
    short: %i[identifier name offset],
    abbr: %i[identifier abbr],
    full: %i[identifier name abbr offset formatted_offset]
  }.freeze
  private_constant :TIME_ZONE_FORMAT_ATTRS

  # format:
  #   * :full - all available fields
  #   * :short (default)
  #
  # Example:
  #   timezone_data # :short by default
  #   timezone_data(format: :full)
  #
  def timezone_data(format: :short)
    attrs = TIME_ZONE_FORMAT_ATTRS.fetch(format) do
      valid_formats = TIME_ZONE_FORMAT_ATTRS.keys.map { |k| ":#{k}" }.join(", ")
      raise ArgumentError, "Invalid format :#{format}. Valid formats are #{valid_formats}."
    end

    ActiveSupport::TimeZone.all.map do |timezone|
      {
        identifier: timezone.tzinfo.identifier,
        name: timezone.name,
        abbr: timezone.tzinfo.strftime('%Z'),
        offset: timezone.now.utc_offset,
        formatted_offset: timezone.now.formatted_offset
      }.slice(*attrs)
    end
  end

  # The identifiers in `timezone_data` are not unique. Some cities (e.g. London and Edinburgh) have
  # the same `identifier` value (e.g. "Europe/London").
  # This method merges such entries into one, joining the city names.
  # This unique list is better suited for selectboxes etc.
  def timezone_data_with_unique_identifiers(format: :short)
    timezone_data(format: format)
      .group_by { |entry| entry[:identifier] }
      .map do |_identifier, entries|
        names = entries.map { |entry| entry[:name] }.sort.join(', ') # rubocop:disable Rails/Pluck -- Not a ActiveRecord object
        entries.first.merge({ name: names })
      end
  end

  def local_timezone_instance(timezone)
    return Time.zone if timezone.blank?

    ActiveSupport::TimeZone.new(timezone) || Time.zone
  end

  def local_time(timezone)
    return if timezone.blank?

    time_zone_instance = local_timezone_instance(timezone)
    time_zone_instance.now.strftime("%-l:%M %p")
  end
end
