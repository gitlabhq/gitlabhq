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
              "#{location} #{error}".downcase
            end
          end

          def self.name
            'Validator'
          end

          def unknown_keys
            return [] unless config.is_a?(Hash)

            config.keys - @node.class.nodes.keys
          end

          private

          def location
            predecessors = ancestors.map(&:key).compact
            predecessors.append(key_name).join(':')
          end

          def key_name
            if key.blank? || key.nil?
              @node.class.name.demodulize.underscore.humanize
            else
              key
            end
          end
        end
      end
    end
  end
end
