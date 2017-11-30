module Gitlab
  module Ci
    class Config
      module Entry
        module Validatable
          extend ActiveSupport::Concern

          def self.included(node)
            node.aspects.append -> do
              @validator = self.class.validator.new(self)
              @validator.validate(:new)
            end
          end

          def errors
            @validator.messages + descendants.flat_map(&:errors) # rubocop:disable Gitlab/ModuleWithInstanceVariables
          end

          class_methods do
            def validator
              @validator ||= Class.new(Entry::Validator).tap do |validator|
                if defined?(@validations)
                  @validations.each { |rules| validator.class_eval(&rules) }
                end
              end
            end

            private

            def validations(&block)
              (@validations ||= []).append(block)
            end
          end
        end
      end
    end
  end
end
