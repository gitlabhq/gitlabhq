# frozen_string_literal: true

module Ci
  class JobArtifactPolicy < BasePolicy
    # Authorized on the artifact's access attributes so equal artifacts share one evaluation
    delegate { ::Authz::JobArtifactAccess.for(@subject) }
  end
end
