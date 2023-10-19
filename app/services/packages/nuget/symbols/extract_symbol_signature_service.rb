# frozen_string_literal: true

module Packages
  module Nuget
    module Symbols
      class ExtractSymbolSignatureService
        include Gitlab::Utils::StrongMemoize

        # More information about the GUID format can be found here:
        # https://github.com/dotnet/symstore/blob/main/docs/specs/SSQP_Key_Conventions.md#key-formatting-basic-rules
        GUID_START_INDEX = 7
        GUID_END_INDEX = 22
        GUID_PARTS_LENGTHS = [4, 2, 2, 8].freeze
        GUID_AGE_PART = 'FFFFFFFF'
        TWO_CHARACTER_HEX_REGEX = /\h{2}/

        # The extraction of the signature in this service is based on the following documentation:
        # https://github.com/dotnet/symstore/blob/main/docs/specs/SSQP_Key_Conventions.md#portable-pdb-signature

        def initialize(symbol_content)
          @symbol_content = symbol_content
        end

        def execute
          return error_response unless signature

          ServiceResponse.success(payload: signature)
        end

        private

        attr_reader :symbol_content

        def signature
          # Find the index of the first occurrence of 'Blob'
          guid_index = symbol_content.index('Blob')
          return if guid_index.nil?

          # Extract the binary GUID from the symbol content
          guid = symbol_content[(guid_index + GUID_START_INDEX)..(guid_index + GUID_END_INDEX)]
          return if guid.nil?

          # Convert the GUID into an array of two-character hex strings
          guid = guid.unpack('H*').flat_map { |el| el.scan(TWO_CHARACTER_HEX_REGEX) }

          # Reorder the GUID parts based on arbitrary lengths
          guid = GUID_PARTS_LENGTHS.map { |length| guid.shift(length) }

          # Concatenate the parts of the GUID back together
          result = guid.first(3).map(&:reverse)
          result << guid.last
          result = result.join
          result << GUID_AGE_PART
        end
        strong_memoize_attr :signature

        def error_response
          ServiceResponse.error(message: 'Could not find the signature in the symbol file')
        end
      end
    end
  end
end
