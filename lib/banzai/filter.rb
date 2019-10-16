# frozen_string_literal: true

module Banzai
  module Filter
    def self.[](name)
      const_get("#{name.to_s.camelize}Filter", false)
    end
  end
end
