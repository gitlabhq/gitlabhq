# frozen_string_literal: true

module Releases
  class CreateService < BaseService
    include Releases::Concerns

    def execute
      return error('Access Denied', 403) unless allowed?
      return error('Release already exists', 409) if release
      return error("Milestone(s) not found: #{inexistent_milestones.join(', ')}", 400) if inexistent_milestones.any?

      tag = ensure_tag

      return tag unless tag.is_a?(Gitlab::Git::Tag)

      create_release(tag)
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
      Ability.allowed?(current_user, :create_release, project)
    end

    def create_release(tag)
      release = build_release(tag)

      release.save!

      notify_create_release(release)

      create_evidence!(release)

      success(tag: tag, release: release)
    rescue => e
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

    def create_evidence!(release)
      return if release.historical_release?

      if release.upcoming_release?
        CreateEvidenceWorker.perform_at(release.released_at, release.id)
      else
        CreateEvidenceWorker.perform_async(release.id)
      end
    end
  end
end
