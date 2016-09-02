module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents a set of jobs.
        #
        class Jobs < Entry
          include Validatable

          validations do
            validates :config, type: Hash

            validate do
              unless has_visible_job?
                errors.add(:config, 'should contain at least one visible job')
              end
            end

            def has_visible_job?
              config.any? { |name, _| !hidden?(name) }
            end
          end

          def hidden?(name)
            name.to_s.start_with?('.')
          end

          private

          def compose!
            @config.each do |name, config|
              node = hidden?(name) ? Node::Hidden : Node::Job

              factory = Node::Factory.new(node)
                .value(config || {})
                .metadata(name: name)
                .with(key: name, parent: self,
                      description: "#{name} job definition.")

              @entries[name] = factory.create!
            end
          end
        end
      end
    end
  end
end
