# frozen_string_literal: true

module Packages
  module Nuget
    module Symbols
      class ExtractSignatureAndChecksumService
        include Gitlab::Utils::StrongMemoize

        # More information about the GUID format can be found here:
        # https://github.com/dotnet/symstore/blob/main/docs/specs/SSQP_Key_Conventions.md#key-formatting-basic-rules
        GUID_START_INDEX = 7
        GUID_END_INDEX = 26
        SIGNATURE_LENGTH = 16
        TWENTY_ZEROED_BYTES = "\u0000" * 20
        GUID_PARTS_LENGTHS = [4, 2, 2, 8].freeze
        GUID_AGE_PART = 'FFFFFFFF'
        TWO_CHARACTER_HEX_REGEX = /\h{2}/
        GUID_CHUNK_SIZE = 256.bytes
        SHA_CHUNK_SIZE = 16.kilobytes

        # The extraction of the signature in this service is based on the following documentation:
        # https://github.com/dotnet/symstore/blob/main/docs/specs/SSQP_Key_Conventions.md#portable-pdb-signature

        def initialize(file)
          @file = file
        end

        def execute
          return error_response unless signature

          ServiceResponse.success(payload: { signature: signature, checksum: checksum })
        end

        private

        attr_reader :file

        def signature
          return unless pdb_id

          # Convert the GUID into an array of two-character hex strings
          guid = pdb_id.first(SIGNATURE_LENGTH).unpack('H*').flat_map { |el| el.scan(TWO_CHARACTER_HEX_REGEX) }

          # Reorder the GUID parts based on arbitrary lengths
          guid = GUID_PARTS_LENGTHS.map { |length| guid.shift(length) }

          # Concatenate the parts of the GUID back together
          result = guid.first(3).map(&:reverse)
          result << guid.last
          result = result.join
          result << GUID_AGE_PART
        end
        strong_memoize_attr :signature

        # https://github.com/dotnet/corefx/blob/master/src/System.Reflection.Metadata/specs/PE-COFF.md#portable-pdb-checksum
        def checksum
          sha = OpenSSL::Digest.new('SHA256')
          count = 0
          chunk = (+'').force_encoding(Encoding::BINARY)
          file.rewind

          while file.read(SHA_CHUNK_SIZE, chunk)
            count += 1
            chunk[pdb_id] = TWENTY_ZEROED_BYTES if count == 1
            sha.update(chunk)
          end

          sha.hexdigest
        end

        def pdb_id
          # The ID is located in the first 256 bytes of the symbol `.pdb` file
          chunk = file.read(GUID_CHUNK_SIZE)
          return unless chunk

          # Find the index of the first occurrence of 'Blob'
          guid_index = chunk.index('Blob')
          return unless guid_index

          # Extract the binary GUID from the symbol content
          chunk[(guid_index + GUID_START_INDEX)..(guid_index + GUID_END_INDEX)]
        end
        strong_memoize_attr :pdb_id

        def error_response
          ServiceResponse.error(message: 'Could not find the signature in the symbol file')
        end
      end
    end
  end
end
