module Gitlab
  module Ci
    class Config
      module Node
        class Validator < SimpleDelegator
          include ActiveModel::Validations
          include Node::Validators

          def initialize(node)
            super(node)
            @node = node
          end

          def messages
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
