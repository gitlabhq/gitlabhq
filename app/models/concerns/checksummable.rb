# frozen_string_literal: true

module Checksummable
  extend ActiveSupport::Concern

  class_methods do
    def hexdigest(path)
      Digest::SHA256.file(path).hexdigest
    end
  end
end
