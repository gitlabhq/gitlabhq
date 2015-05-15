module AttrEncrypted
  module Adapters
    module ActiveRecord
      protected

      def attribute_instance_methods_as_symbols
        # We add accessor methods of the db columns to the list of instance
        # methods returned to let ActiveRecord define the accessor methods
        # for the db columns
        if connection_established? && table_exists?
          columns_hash.keys.inject(super) {|instance_methods, column_name| instance_methods.concat [column_name.to_sym, :"#{column_name}="]}
        else
          super
        end
      end

      def connection_established?
        begin
          # use with_connection so the connection doesn't stay pinned to the thread.
          ActiveRecord::Base.connection_pool.with_connection {
            ActiveRecord::Base.connection.active?
          }
        rescue Exception
          false
        end
      end
    end
  end
end
