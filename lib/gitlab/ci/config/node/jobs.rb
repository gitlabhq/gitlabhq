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

            with_options on: :processed do
              validate do
                unless has_visible_job?
                  errors.add(:config, 'should contain at least one visible job')
                end
              end
            end
          end

          def nodes
            @config
          end

          def has_visible_job?
            @entries.values.any?(&:relevant?)
          end

          private

          def create(name, config)
            Node::Factory.new(job_class(name))
              .value(config || {})
              .metadata(name: name)
              .with(key: name, parent: self,
                    description: "#{name} job definition.")
              .create!
          end

          def job_class(name)
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
