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
            validate :jobs_presence, on: :after

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
            job_node(name).new(config, job_attributes(name))
          end

          def job_node(name)
            name.to_s.start_with?('.') ? Node::HiddenJob : Node::Job
          end

          def job_attributes(name)
            @attributes.merge(key: name,
                              parent: self,
                              description: "#{name} job definition.")
          end
        end
      end
    end
  end
end
