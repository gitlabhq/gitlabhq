module Gitlab
  module Ci
    class Config
      module Node
        module Validatable
          extend ActiveSupport::Concern

          class_methods do
            def validator
              @validator ||= Class.new(Node::Validator).tap do |validator|
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
