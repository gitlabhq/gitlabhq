# frozen_string_literal: true

module Gitlab
  module Database
    # Class for casting binary data to int.
    #
    # Using X509SerialNumberAttribute allows you to store X509 certificate
    # serial number values as binary while still using integer to access them.
    # rfc 5280 - 4.1.2.2  Serial number (20 octets is the maximum), could be:
    # - 1461501637330902918203684832716283019655932542975
    # - 0xffffffffffffffffffffffffffffffffffffffff
    class X509SerialNumberAttribute < ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Bytea
      PACK_FORMAT = 'H*'

      def deserialize(value)
        value = super(value)
        value ? value.unpack1(PACK_FORMAT).to_i : nil
      end

      def serialize(value)
        arg = value ? [value.to_s].pack(PACK_FORMAT) : nil
        super(arg)
      end
    end
  end
end
