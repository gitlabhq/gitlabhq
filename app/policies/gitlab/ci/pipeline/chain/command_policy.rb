# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class CommandPolicy < BasePolicy
          delegate(:project) { @subject.project }
        end
      end
    end
  end
end

Gitlab::Ci::Pipeline::Chain::CommandPolicy.prepend_mod
