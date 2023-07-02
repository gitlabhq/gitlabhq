# frozen_string_literal: true

module Projects
  module RemoveRefs
    extend ActiveSupport::Concern
    include Gitlab::ExclusiveLeaseHelpers

    LOCK_RETRY = 3
    LOCK_TTL = 5.minutes
    LOCK_SLEEP = 0.5.seconds

    def serialized_remove_refs(project_id, &blk)
      in_lock("projects/#{project_id}/serialized_remove_refs", **lock_params, &blk)
    end

    def lock_params
      {
        ttl: LOCK_TTL,
        retries: LOCK_RETRY,
        sleep_sec: LOCK_SLEEP
      }
    end
  end
end
