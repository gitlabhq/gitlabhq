# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Artifacts
        class Path
          def initialize(path)
            @path = path.dup.force_encoding('UTF-8')
          end

          def valid?
            nonzero? && utf8?
          end

          def directory?
            @path.end_with?('/')
          end

          def name
            @path.split('/').last.to_s
          end

          def nodes
            @path.count('/')
          end

          def to_s
            @path.tap do |path|
              unless nonzero?
                raise ArgumentError, 'Path contains zero byte character!'
              end

              unless utf8?
                raise ArgumentError, 'Path contains non-UTF-8 byte sequence!'
              end
            end
          end

          private

          def nonzero?
            @path.exclude?("\0")
          end

          def utf8?
            @path.valid_encoding?
          end
        end
      end
    end
  end
end
