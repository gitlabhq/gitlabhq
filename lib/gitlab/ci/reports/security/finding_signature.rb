# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class FindingSignature
          include VulnerabilityFindingSignatureHelpers

          attr_accessor :algorithm_type, :signature_value

          def initialize(params = {})
            @algorithm_type = params[:algorithm_type]
            @signature_value = params[:signature_value]
          end

          def signature_sha
            Digest::SHA1.digest(signature_value)
          end

          def signature_hex
            signature_sha.unpack1("H*")
          end

          def to_hash
            {
              algorithm_type: algorithm_type,
              signature_sha: signature_sha
            }
          end

          def valid?
            algorithm_types.key?(algorithm_type)
          end

          def eql?(other)
            other.algorithm_type == algorithm_type &&
              other.signature_sha == signature_sha
          end

          alias_method :==, :eql?
        end
      end
    end
  end
end
