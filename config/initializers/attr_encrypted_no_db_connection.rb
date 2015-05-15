module AttrEncrypted
  module Adapters
    module ActiveRecord
      def attribute_instance_methods_as_symbols_with_no_db_connection
        if connection_established?
          # Call version from AttrEncrypted::Adapters::ActiveRecord
          attribute_instance_methods_as_symbols_without_no_db_connection
        else
          # Call version from AttrEncrypted (`super` with regards to AttrEncrypted::Adapters::ActiveRecord)
          AttrEncrypted.instance_method(:attribute_instance_methods_as_symbols).bind(self).call
        end
      end

      alias_method_chain :attribute_instance_methods_as_symbols, :no_db_connection

      private

      def connection_established?
        begin
          # Use with_connection so the connection doesn't stay pinned to the thread.
          ActiveRecord::Base.connection_pool.with_connection { |con| con.active? }
        rescue Exception
          false
        end
      end
    end
  end
end
