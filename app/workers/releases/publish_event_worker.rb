# frozen_string_literal: true

module Releases
  class PublishEventWorker
    include ApplicationWorker
    include CronjobQueue

    idempotent!
    data_consistency :always
    feature_category :release_orchestration

    def perform
      releases_published = 0

      Release.waiting_for_publish_event.each_batch(of: 100) do |releases|
        releases.each do |release|
          with_context(project: release.project) do
            ::Gitlab::EventStore.publish(
              ::Projects::ReleasePublishedEvent.new(data: { release_id: release.id })
            )

            releases_published += 1
          end
        end

        releases.touch_all(:release_published_at)
      end

      log_extra_metadata_on_done(:releases_published, releases_published) if releases_published > 0
    end
  end
end
