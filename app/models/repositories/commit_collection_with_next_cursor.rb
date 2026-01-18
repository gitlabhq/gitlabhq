# frozen_string_literal: true

# A collection of Commits for a container and Git reference
# with the next pagination cursor instead of page number. This is used for the
# list commits RPC which uses cursor pagination but we want to follow the same
# object API as the CommitCollection
module Repositories
  class CommitCollectionWithNextCursor < ::CommitCollection
    def initialize(container, commits, ref = nil, next_cursor: nil)
      super(container, commits, ref)
      @next_cursor = next_cursor
    end

    attr_reader :next_cursor
    alias_method :next_page, :next_cursor
  end
end
