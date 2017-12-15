module Geo
  module Model
    extend ActiveSupport::Concern

    included do
      def self.table_name_prefix
        "geo_"
      end
    end
  end
end
