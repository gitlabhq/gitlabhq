# frozen_string_literal: true

module Blobs
  class Notebook < ::Blob
    attr_reader :data

    def initialize(blob, data)
      super(blob.__getobj__, blob.container)
      @data = data
    end
  end
end
