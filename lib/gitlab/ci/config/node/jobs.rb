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
            validate :jobs_presence, on: :processed

            def jobs_presence
              unless relevant?
                errors.add(:config, 'should contain at least one visible job')
              end
            end
          end

          def nodes
            @config
          end

          def relevant?
            @entries.values.any?(&:relevant?)
          end

          private

          def create(name, config)
            Node::Factory.new(job_node(name))
              .value(config || {})
              .with(key: name, parent: self, global: @global)
              .with(description: "#{name} job definition.")
              .create!
          end

          def job_node(name)
            if name.to_s.start_with?('.')
              Node::HiddenJob
            else
              Node::Job
            end
          end
        end
      end
    end
  end
end
