# frozen_string_literal: true

module AttrEncrypted
  module Adapters
    module ActiveRecord
      module GitlabMonkeyPatches
        # Prevent attr_encrypted from defining virtual accessors for encryption
        # data when the code and schema are out of sync. See this issue for more
        # details: https://github.com/attr-encrypted/attr_encrypted/issues/332
        def attribute_instance_methods_as_symbols_available?
          false
        end

        # Prevent attr_encrypted from checking out a database connection
        # indefinitely. The result of this method is only used when the former
        # is true, but it is called unconditionally, so there is still value to
        # ensuring the connection is released
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

        protected

        # The attr_encrypted gem is not actively maintained
        # At the same time it contains the code that raises kwargs deprecation warnings:
        # https://github.com/attr-encrypted/attr_encrypted/blob/master/lib/attr_encrypted/adapters/active_record.rb#L65
        #
        def attr_encrypted(*attrs)
          super

          attr = attrs.first

          redefine_method(:"#{attr}_changed?") do |**options|
            attribute_changed?(attr, **options)
          end
        end
      end
    end
  end
end

# As of v3.1.0, the attr_encrypted gem defines the AttrEncrypted and
# AttrEncrypted::Adapters::ActiveRecord modules, and uses "extend" to mix them
# into the ActiveRecord::Base class. This intervention overrides utility methods
# defined by attr_encrypted to fix two bugs, as detailed above.
#
# The methods are used here: https://github.com/attr-encrypted/attr_encrypted/blob/3.1.0/lib/attr_encrypted.rb#L145-158
ActiveSupport.on_load(:active_record) do
  extend AttrEncrypted::Adapters::ActiveRecord::GitlabMonkeyPatches
end
