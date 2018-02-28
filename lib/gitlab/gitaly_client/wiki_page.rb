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
