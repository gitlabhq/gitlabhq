# frozen_string_literal: true

module Gitlab
  module Config
    module Entry
      module Validatable
        extend ActiveSupport::Concern

        def self.included(node)
          node.with_aspect -> do
            validate(:new)
          end
        end

        def validator
          @validator ||= self.class.validator.new(self)
        end

        def validate(context = nil)
          validator.validate(context)
        end

        def compose!(deps = nil, &blk)
          super(deps, &blk)

          validate(:composed)
        end

        def errors
          validator.messages + descendants.flat_map(&:errors)
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
