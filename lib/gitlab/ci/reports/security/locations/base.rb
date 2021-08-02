# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        module Locations
          class Base
            include ::Gitlab::Utils::StrongMemoize

            def ==(other)
              other.fingerprint == fingerprint
            end

            def fingerprint
              strong_memoize(:fingerprint) do
                Digest::SHA1.hexdigest(fingerprint_data)
              end
            end

            def as_json(options = nil)
              fingerprint # side-effect call to initialize the ivar for serialization

              super
            end

            def fingerprint_path
              fingerprint_data
            end

            private

            def fingerprint_data
              raise NotImplementedError
            end
          end
        end
      end
    end
  end
end
