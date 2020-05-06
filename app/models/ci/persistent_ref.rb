# frozen_string_literal: true

module Ci
  ##
  # The persistent pipeline ref to ensure runners can safely fetch source code
  # even if force-push/source-branch-deletion happens.
  class PersistentRef
    include ActiveModel::Model

    attr_accessor :pipeline

    delegate :project, :sha, to: :pipeline
    delegate :repository, to: :project
    delegate :ref_exists?, :create_ref, :delete_refs, to: :repository

    def exist?
      ref_exists?(path)
    rescue
      false
    end

    def create
      create_ref(sha, path)
    rescue => e
      Gitlab::ErrorTracking
        .track_exception(e, pipeline_id: pipeline.id)
    end

    def delete
      delete_refs(path)
    rescue Gitlab::Git::Repository::NoRepository
      # no-op
    rescue => e
      Gitlab::ErrorTracking
        .track_exception(e, pipeline_id: pipeline.id)
    end

    def path
      "refs/#{Repository::REF_PIPELINES}/#{pipeline.id}"
    end
  end
end
