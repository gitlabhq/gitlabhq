# frozen_string_literal: true

module Ci
  class JobArtifactPolicy < BasePolicy
    delegate { @subject.job.project }
  end
end
