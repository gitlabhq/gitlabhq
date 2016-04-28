module Banzai
  module ReferenceParser
    def self.[](name)
      const_get("#{name.to_s.camelize}Parser")
    end
  end
end
