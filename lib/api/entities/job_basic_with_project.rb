# frozen_string_literal: true

module API
  module Entities
    class JobBasicWithProject < Entities::JobBasic
      expose :project, with: Entities::ProjectIdentity
    end
  end
end
