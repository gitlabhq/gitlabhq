# frozen_string_literal: true

class CarrierWaveStringFile < StringIO
  attr_reader :original_filename

  def initialize(data, original_filename = "")
    super(data)

    @original_filename = original_filename
  end
end
