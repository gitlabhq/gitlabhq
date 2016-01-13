module Banzai
  module Pipeline
    def self.[](name)
      name ||= :full
      const_get("#{name.to_s.camelize}Pipeline")
    end
  end
end
