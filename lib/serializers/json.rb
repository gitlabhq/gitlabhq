# frozen_string_literal: true

module Serializers
  # This serializer exports data as JSON,
  # it is designed to be used with interwork compatibility between MySQL and PostgreSQL
  # implementations, as used version of MySQL does not support native json type
  #
  # Secondly, the loader makes the resulting hash to have deep indifferent access
  class JSON
    class << self
      def dump(obj)
        # MySQL stores data as text
        # look at ./config/initializers/ar_mysql_jsonb_support.rb
        if Gitlab::Database.mysql?
          obj = ActiveSupport::JSON.encode(obj)
        end

        obj
      end

      def load(data)
        return if data.nil?

        # On MySQL we store data as text
        # look at ./config/initializers/ar_mysql_jsonb_support.rb
        if Gitlab::Database.mysql?
          data = ActiveSupport::JSON.decode(data)
        end

        Gitlab::Utils.deep_indifferent_access(data)
      end
    end
  end
end
