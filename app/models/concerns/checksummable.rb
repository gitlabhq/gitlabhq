# frozen_string_literal: true

module Checksummable
  extend ActiveSupport::Concern

  def crc32(data)
    Zlib.crc32(data)
  end

  class_methods do
    def hexdigest(path)
      ::Digest::SHA256.file(path).hexdigest
    end
  end
end
