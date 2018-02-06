module Banzai
  module Filter
    def self.[](name)
      const_get("#{name.to_s.camelize}Filter")
    end
  end
end
