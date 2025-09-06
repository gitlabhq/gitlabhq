# frozen_string_literal: true

module Ci
  module ProcessablePolicy
    extend ActiveSupport::Concern

    included do
      include Ci::JobAbilities

      condition(:archived, scope: :subject) do
        @subject.archived?(log: true)
      end

      rule { archived }.policy do
        prevent(*job_user_facing_update_abilities)
      end
    end
  end
end
