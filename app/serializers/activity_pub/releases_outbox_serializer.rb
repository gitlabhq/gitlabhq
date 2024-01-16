# frozen_string_literal: true

module ActivityPub
  class ReleasesOutboxSerializer < CollectionSerializer
    entity ReleaseEntity
  end
end
