# frozen_string_literal: true

module Checksummable
  extend ActiveSupport::Concern

  class_methods do
    def crc32(data)
      Zlib.crc32(data)
    end

    def hexdigest(path)
      ::Digest::SHA256.file(path).hexdigest
    end
  end
end
