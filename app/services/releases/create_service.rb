# frozen_string_literal: true

module Releases
  class CreateService < Releases::BaseService
    def execute
      return error('Access Denied', 403) unless allowed?
      return error('Release already exists', 409) if release
      return error("Milestone(s) not found: #{inexistent_milestones.join(', ')}", 400) if inexistent_milestones.any?

      track_protected_tag_access_error!

      # should be found before the creation of new tag
      # because tag creation can spawn new pipeline
      # which won't have any data for evidence yet
      evidence_pipeline = Releases::EvidencePipelineFinder.new(project, params).execute

      tag = ensure_tag

      return tag unless tag.is_a?(Gitlab::Git::Tag)

      create_release(tag, evidence_pipeline)
    end

    def find_or_build_release
      release || build_release(existing_tag)
    end

    private

    def ensure_tag
      existing_tag || create_tag
    end

    def create_tag
      return error('Ref is not specified', 422) unless ref

      result = Tags::CreateService
        .new(project, current_user)
        .execute(tag_name, ref, nil)

      return result unless result[:status] == :success

      result[:tag]
    end

    def allowed?
      Ability.allowed?(current_user, :create_release, project) && can_create_tag?
    end

    def can_create_tag?
      return true unless ::Feature.enabled?(:evalute_protected_tag_for_release_permissions, project, default_enabled: :yaml)

      ::Gitlab::UserAccess.new(current_user, container: project).can_create_tag?(tag_name)
    end

    def create_release(tag, evidence_pipeline)
      release = build_release(tag)

      release.save!

      notify_create_release(release)

      execute_hooks(release, 'create')

      create_evidence!(release, evidence_pipeline)

      success(tag: tag, release: release)
    rescue StandardError => e
      error(e.message, 400)
    end

    def notify_create_release(release)
      NotificationService.new.async.send_new_release_notifications(release)
    end

    def build_release(tag)
      project.releases.build(
        name: name,
        description: description,
        author: current_user,
        tag: tag.name,
        sha: tag.dereferenced_target.sha,
        released_at: released_at,
        links_attributes: params.dig(:assets, 'links') || [],
        milestones: milestones
      )
    end

    def create_evidence!(release, pipeline)
      return if release.historical_release? || release.upcoming_release?

      ::Releases::CreateEvidenceWorker.perform_async(release.id, pipeline&.id)
    end
  end
end
