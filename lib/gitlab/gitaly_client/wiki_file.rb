module Gitlab
  module GitalyClient
    class WikiFile
      FIELDS = %i(name mime_type path raw_data).freeze

      attr_accessor(*FIELDS)

      def initialize(params)
        params = params.with_indifferent_access

        FIELDS.each do |field|
          instance_variable_set("@#{field}", params[field])
        end
      end
    end
  end
end
