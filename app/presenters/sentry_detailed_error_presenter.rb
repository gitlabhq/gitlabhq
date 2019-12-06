# frozen_string_literal: true

class SentryDetailedErrorPresenter < Gitlab::View::Presenter::Delegated
  presents :error

  FrequencyStruct = Struct.new(:time, :count, keyword_init: true)

  def frequency
    utc_offset = Time.zone_offset('UTC')

    error.frequency.map do |f|
      FrequencyStruct.new(time: Time.at(f[0], in: utc_offset), count: f[1])
    end
  end
end
