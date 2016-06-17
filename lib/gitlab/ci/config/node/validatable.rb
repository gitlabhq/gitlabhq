module Gitlab
  module Ci
    class Config
      module Node
        module Validatable
          extend ActiveSupport::Concern

          class_methods do
            def validator
              validator = Class.new(Node::Validator)

              if defined?(@validations)
                @validations.each { |rules| validator.class_eval(&rules) }
              end

              validator
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
