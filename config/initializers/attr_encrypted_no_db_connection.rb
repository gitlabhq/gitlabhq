# frozen_string_literal: true

raise 'This patch is only tested with attr_encrypted v3.1.0' unless AttrEncrypted::Version.string == '3.1.0'

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
