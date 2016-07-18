module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents a concrete CI/CD job.
        #
        class Job < Entry
          include Configurable

          validations do
            validates :config, presence: true
            validates :name, presence: true
            validates :name, type: Symbol
          end

          node :before_script, Script,
            description: 'Global before script overridden in this job.'

          node :script, Commands,
            description: 'Commands that will be executed in this job.'

          node :stage, Stage,
            description: 'Pipeline stage this job will be executed into.'

          node :type, Stage,
            description: 'Deprecated: stage this job will be executed into.'

          node :after_script, Script,
            description: 'Commands that will be executed when finishing job.'

          node :cache, Cache,
            description: 'Cache definition for this job.'

          node :image, Image,
            description: 'Image that will be used to execute this job.'

          node :services, Services,
            description: 'Services that will be used to execute this job.'

          helpers :before_script, :script, :stage, :type, :after_script,
                  :cache, :image, :services

          def name
            @metadata[:name]
          end

          def value
            @config.merge(to_hash.compact)
          end

          private

          def to_hash
            { name: name,
              before_script: before_script,
              script: script,
              image: image,
              services: services,
              stage: stage,
              cache: cache,
              after_script: after_script }
          end

          def compose!
            super

            if type_defined? && !stage_defined?
              @entries[:stage] = @entries[:type]
            end

            @entries.delete(:type)
          end
        end
      end
    end
  end
end
