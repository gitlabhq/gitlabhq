# frozen_string_literal: true

class SentryErrorPresenter < Gitlab::View::Presenter::Delegated
  presents nil, as: :error

  FrequencyStruct = Struct.new(:time, :count, keyword_init: true)

  def first_seen
    DateTime.parse(error.first_seen)
  end

  def last_seen
    DateTime.parse(error.last_seen)
  end

  def project_id
    Gitlab::GlobalId.build(model_name: 'SentryProject', id: error.project_id).to_s
  end

  def frequency
    utc_offset = Time.zone_offset('UTC')

    error.frequency.map do |f|
      FrequencyStruct.new(time: Time.at(f[0], in: utc_offset), count: f[1])
    end
  end
end
