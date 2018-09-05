# frozen_string_literal: true

module EE
  module BuildDetailEntity
    extend ActiveSupport::Concern

    prepended do
      expose :runners do
        expose :quota, if: -> (*) { project.shared_runners_minutes_limit_enabled? } do
          expose :used do |runner|
            project.shared_runners_minutes.to_i
          end

          expose :limit do |runner|
            project.actual_shared_runners_minutes_limit.to_i
          end
        end
      end
    end
  end
end
