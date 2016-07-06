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
            @nodes.values.any?(&:relevant?)
          end

          def leaf?
            false
          end

          private

          def create_node(key, essence)
            fabricate_job(key, essence).tap do |job|
              job.key = key
              job.parent = self
              job.description = "#{key} job definition."
            end
          end

          def fabricate_job(key, essence)
            if key.to_s.start_with?('.')
              Node::HiddenJob.new(essence)
            else
              Node::Job.new(essence)
            end
          end
        end
      end
    end
  end
end
