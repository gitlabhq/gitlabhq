module Gitlab
  module Ci
    class Config
      module Node
        class Validator < SimpleDelegator
          def initialize(node)
            @node = node
            super(node)
            validate
          end

          def full_errors
            errors.full_messages.map do |error|
              "#{@node.key} #{error}".humanize
            end
          end

          def self.name
            'Validator'
          end
        end
      end
    end
  end
end
