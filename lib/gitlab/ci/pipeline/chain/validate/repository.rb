# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Validate
          class Repository < Chain::Base
            include Chain::Helpers

            def perform!
              if @command.ambiguous_ref?
                return error('Ref is ambiguous')
              end

              unless @command.ref_exists?
                return error('Reference not found')
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
