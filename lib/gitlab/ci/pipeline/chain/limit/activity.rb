# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Limit
          class Activity < Chain::Base
            def perform!
              # to be overridden in EE
            end

            def break?
              false # to be overridden in EE
            end
          end
        end
      end
    end
  end
end

Gitlab::Ci::Pipeline::Chain::Limit::Activity.prepend_mod_with('Gitlab::Ci::Pipeline::Chain::Limit::Activity')
