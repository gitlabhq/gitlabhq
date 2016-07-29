module Gitlab
  module Ci
    class Config
      module Node
        ##
        # This mixin is responsible for adding DSL, which purpose is to
        # simplifly process of adding child nodes.
        #
        # This can be used only if parent node is a configuration entry that
        # holds a hash as a configuration value, for example:
        #
        # job:
        #   script: ...
        #   artifacts: ...
        #
        module Configurable
          extend ActiveSupport::Concern
          include Validatable

          included do
            validations do
              validates :config, type: Hash
            end
          end

          private

          def compose!
            self.class.nodes.each do |key, factory|
              factory
                .value(@config[key])
                .with(key: key, parent: self)

              @entries[key] = factory.create!
            end
          end

          class_methods do
            def nodes
              Hash[(@nodes || {}).map { |key, factory| [key, factory.dup] }]
            end

            private

            def node(key, node, metadata)
              factory = Node::Factory.new(node)
                .with(description: metadata[:description])

              (@nodes ||= {}).merge!(key.to_sym => factory)
            end

            def helpers(*nodes)
              nodes.each do |symbol|
                define_method("#{symbol}_defined?") do
                  @entries[symbol].specified? if @entries[symbol]
                end

                define_method("#{symbol}_value") do
                  return unless @entries[symbol] && @entries[symbol].valid?

                  @entries[symbol].value
                end

                alias_method symbol.to_sym, "#{symbol}_value".to_sym
              end
            end
          end
        end
      end
    end
  end
end
