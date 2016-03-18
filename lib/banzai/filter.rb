require 'active_support/core_ext/string/output_safety'

module Banzai
  module Filter
    def self.[](name)
      const_get("#{name.to_s.camelize}Filter")
    end
  end
end
