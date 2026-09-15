# frozen_string_literal: true

module Gitlab
  module PolicyStore
    class RuleTranspiler
      module Emitters
        class Custom < Base
          include RegoPackage

          def custom_program
            invalid!("custom rule requires Rego source in value") unless value.is_a?(String)

            # Checked ahead of the emptiness test because the program is stored as authored,
            # so nothing downstream re-encodes it, and the package scan below cannot match a
            # String whose encoding the regexp is incompatible with.
            invalid!("custom rule source must be UTF-8, found #{value.encoding}") unless utf8_compatible?(value)

            invalid!("custom rule requires Rego source in value") if unusable_string?(value)

            declared_package = declared_in(value)
            unless declared_package == PACKAGE_NAME
              invalid!("custom rule must declare `package #{PACKAGE_NAME}`, found #{reported_value(declared_package)}")
            end

            value
          end
        end
      end
    end
  end
end
