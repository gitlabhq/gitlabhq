module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Base abstract class for each configuration entry node.
        #
        class Entry
          class InvalidError < StandardError; end
          include Validatable

          attr_reader :config
          attr_accessor :key, :description

          def initialize(config)
            @config = config
            @nodes = {}
            @validator = self.class.validator.new(self)
          end

          def process!
            return if leaf?
            return unless valid?

            compose!
            process_nodes!
          end

          def nodes
            @nodes.values
          end

          def leaf?
            allowed_nodes.none?
          end

          def key
            @key || self.class.name.demodulize.underscore
          end

          def valid?
            errors.none?
          end

          def errors
            @validator.full_errors +
              nodes.map(&:errors).flatten
          end

          def allowed_nodes
            {}
          end

          def value
            raise NotImplementedError
          end

          private

          def compose!
            allowed_nodes.each do |key, essence|
              @nodes[key] = create_node(key, essence)
            end
          end

          def process_nodes!
            nodes.each(&:process!)
          end

          def create_node(key, essence)
            raise NotImplementedError
          end
        end
      end
    end
  end
end
