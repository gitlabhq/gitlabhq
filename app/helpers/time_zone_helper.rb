# frozen_string_literal: true

module TimeZoneHelper
  TIME_ZONE_FORMAT_ATTRS = {
    short: %i[identifier name offset],
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
      valid_formats = TIME_ZONE_FORMAT_ATTRS.keys.map { |k| ":#{k}"}.join(", ")
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
end
