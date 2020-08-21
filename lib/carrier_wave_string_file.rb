# frozen_string_literal: true

class CarrierWaveStringFile < StringIO
  def original_filename
    ""
  end

  def self.new_file(file_content:, filename:, content_type: "application/octet-stream")
    {
      "tempfile" => StringIO.new(file_content),
      "filename" => filename,
      "content_type" => content_type
    }
  end
end
