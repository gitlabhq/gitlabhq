# frozen_string_literal: true

module Authz
  # The only attributes :read_job_artifacts may depend on. DeclarativePolicy caches
  # on #id, so artifacts with equal attributes share one policy evaluation.
  # To let Authz::JobArtifactAccessPolicy read a new attribute, add it here and set
  # it in both .for and Ci::JobArtifact.access_subjects_by_job_id.
  class JobArtifactAccess < Data.define(:project, :accessibility, :file_type)
    def self.for(artifact)
      new(project: artifact.job.project, accessibility: artifact.accessibility, file_type: artifact.file_type)
    end

    # The policy compares strings, so a symbol like :none would otherwise fail open
    def initialize(project:, accessibility:, file_type:)
      super(project: project, accessibility: accessibility.to_s, file_type: file_type.to_s)
    end

    # Built from every member so a new member can't make two subjects share a cache entry
    def id
      deconstruct.map { |value| value.is_a?(::ApplicationRecord) ? value.id : value }.join(':')
    end
  end
end
