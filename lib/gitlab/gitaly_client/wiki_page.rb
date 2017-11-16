module Gitlab
  module GitalyClient
    class WikiPage
      FIELDS = %i(title format url_path path name historical raw_data).freeze

      attr_accessor(*FIELDS)

      def initialize(params)
        params = params.with_indifferent_access

        FIELDS.each do |field|
          instance_variable_set("@#{field}", params[field])
        end

        # All gRPC strings in a response are frozen, so we get an unfrozen
        # version here so appending to `raw_data` doesn't blow up.
        @raw_data = @raw_data.dup
      end

      def historical?
        @historical
      end

      def format
        @format.to_sym
      end
    end
  end
end
