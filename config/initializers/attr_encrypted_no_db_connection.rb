module AttrEncrypted
  module Adapters
    module ActiveRecord
      module DBConnectionQuerier
        def attribute_instance_methods_as_symbols
          # Use with_connection so the connection doesn't stay pinned to the thread.
          connected = ::ActiveRecord::Base.connection_pool.with_connection(&:active?) rescue false

          if connected
            # Call version from AttrEncrypted::Adapters::ActiveRecord
            super
          else
            # Call version from AttrEncrypted, i.e., `super` with regards to AttrEncrypted::Adapters::ActiveRecord
            AttrEncrypted.instance_method(:attribute_instance_methods_as_symbols).bind(self).call
          end
        end
      end
      prepend DBConnectionQuerier
    end
  end
end
