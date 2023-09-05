# frozen_string_literal: true

module ActivityPub
  class ReleasesOutboxSerializer < ActivityStreamsSerializer
    include WithPagination

    entity ReleaseEntity
  end
end
