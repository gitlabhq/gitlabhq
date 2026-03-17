# frozen_string_literal: true

module Cells
  module Serialization
    def to_bytes(rails_primary_key)
      case rails_primary_key
      when Integer
        [rails_primary_key].pack("Q>") # uint64 big-endian
      when String
        if Gitlab::UUID.uuid?(rails_primary_key)
          [rails_primary_key.delete("-")].pack("H*") # UUID: remove dashes and encode as hex
        else
          rails_primary_key # Raw string, pass as is
        end
      else
        raise ArgumentError, "Unsupported primary key type: #{rails_primary_key.class}"
      end
    end
    module_function :to_bytes
  end
end
