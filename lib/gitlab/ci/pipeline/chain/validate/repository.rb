# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Validate
          class Repository < Chain::Base
            include Chain::Helpers

            REFERENCE_NOT_FOUND_MESSAGE = 'Reference not found'

            def perform!
              if @command.ambiguous_ref?
                return error('Ref is ambiguous')
              end

              unless @command.ref_exists?
                return error(REFERENCE_NOT_FOUND_MESSAGE)
              end

              unless @command.sha
                error('Commit not found')
              end
            end

            def break?
              @pipeline.errors.any?
            end
          end
        end
      end
    end
  end
end
