# frozen_string_literal: true

module ContainerRegistry
  class Config
    attr_reader :tag, :blob, :data

    def initialize(tag, blob)
      @tag = tag
      @blob = blob
      @data = Gitlab::Json.parse(blob.data)
    end

    def [](key)
      return unless data

      data[key]
    end
  end
end
