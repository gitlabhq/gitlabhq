# frozen_string_literal: true

class CarrierWaveStringFile < StringIO
  def original_filename
    ""
  end
end
