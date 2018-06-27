module Gitlab
  module Database
    BINARY_TYPE =
      if Gitlab::Database.postgresql?
        # PostgreSQL defines its own class with slightly different
        # behaviour from the default Binary type.
        ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Bytea
      else
        # In Rails 5.0 `Type` has been moved from `ActiveRecord` to `ActiveModel`
        # https://github.com/rails/rails/commit/9cc8c6f3730df3d94c81a55be9ee1b7b4ffd29f6#diff-f8ba7983a51d687976e115adcd95822b
        # Remove this method and leave just `ActiveModel::Type::Binary` when removing Gitlab.rails5? code.
        if Gitlab.rails5?
          ActiveModel::Type::Binary
        else
          ActiveRecord::Type::Binary
        end
      end

    # Class for casting binary data to hexadecimal SHA1 hashes (and vice-versa).
    #
    # Using ShaAttribute allows you to store SHA1 values as binary while still
    # using them as if they were stored as string values. This gives you the
    # ease of use of string values, but without the storage overhead.
    class ShaAttribute < BINARY_TYPE
      PACK_FORMAT = 'H*'.freeze

      # It is called from activerecord-4.2.10/lib/active_record internal methods.
      # Remove this method when removing Gitlab.rails5? code.
      def type_cast_from_database(value)
        unpack_sha(super)
      end

      # It is called from activerecord-4.2.10/lib/active_record internal methods.
      # Remove this method when removing Gitlab.rails5? code.
      def type_cast_for_database(value)
        serialize(value)
      end

      # It is called from activerecord-5.0.6/lib/active_record/attribute.rb
      # Remove this method when removing Gitlab.rails5? code..
      def deserialize(value)
        value = Gitlab.rails5? ? super : method(:type_cast_from_database).super_method.call(value)

        unpack_sha(value)
      end

      # Rename this method to `deserialize(value)` removing Gitlab.rails5? code.
      # Casts binary data to a SHA1 in hexadecimal.
      def unpack_sha(value)
        # Uncomment this line when removing Gitlab.rails5? code.
        # value = super
        value ? value.unpack(PACK_FORMAT)[0] : nil
      end

      # Casts a SHA1 in hexadecimal to the proper binary format.
      def serialize(value)
        arg = value ? [value].pack(PACK_FORMAT) : nil

        Gitlab.rails5? ? super(arg) : method(:type_cast_for_database).super_method.call(arg)
      end
    end
  end
end
