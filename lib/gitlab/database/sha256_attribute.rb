# frozen_string_literal: true

module Gitlab
  module Database
    # Class for casting binary data to hexadecimal SHA256 hashes (and vice-versa).
    #
    # Using Sha256Attribute allows you to store SHA256 values as binary while still
    # using them as if they were stored as string values. This gives you the
    # ease of use of string values, but without the storage overhead.
    class Sha256Attribute < ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Bytea
      # Casts binary data to a SHA256 and remove trailing = and newline from encode64
      def deserialize(value)
        value = super(value)
        if value.present?
          Base64.encode64(value).delete("=").chomp("\n")
        else
          nil
        end
      end

      # Casts a SHA256 in a proper binary format. which is 32 bytes long
      def serialize(value)
        arg = if value.present?
                Base64.decode64(value)
              else
                nil
              end

        super(arg)
      end
    end
  end
end
