# frozen_string_literal: true

module Gitlab
  module Database
    # PostgreSQL defines its own class with slightly different
    # behaviour from the default Binary type.
    BINARY_TYPE = ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Bytea

    # Class for casting binary data to hexadecimal SHA1 hashes (and vice-versa).
    #
    # Using ShaAttribute allows you to store SHA1 values as binary while still
    # using them as if they were stored as string values. This gives you the
    # ease of use of string values, but without the storage overhead.
    class ShaAttribute < BINARY_TYPE
      PACK_FORMAT = 'H*'

      # Casts binary data to a SHA1 in hexadecimal.
      def deserialize(value)
        value = super(value)
        value ? value.unpack1(PACK_FORMAT) : nil
      end

      # Casts a SHA1 in hexadecimal to the proper binary format.
      def serialize(value)
        arg = value ? [value].pack(PACK_FORMAT) : nil

        BINARY_TYPE.new.serialize(arg)
      end

      # Casts a SHA1 in hexadecimal to the proper binary format.
      def self.serialize(value)
        arg = value ? [value].pack(PACK_FORMAT) : nil

        BINARY_TYPE.new.serialize(arg)
      end
    end
  end
end
