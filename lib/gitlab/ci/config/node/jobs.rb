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
          end

          def nodes
            @config
          end

          private

          def create_node(key, essence)
            Node::Job.new(essence).tap do |job|
              job.key = key
              job.parent = self
              job.description = "#{key} job definition."
            end
          end
        end
      end
    end
  end
end
