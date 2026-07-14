# frozen_string_literal: true

module Gitlab
  module Audit
    class OrbitIndexerAuthor < Gitlab::Audit::NullAuthor
      def initialize(name: nil)
        super(id: ORBIT_INDEXER_AUTHOR_ID, name: name)
      end

      # The Orbit indexer authenticates with a service JWT and has no current_user,
      # so its events are attributed to this name instead of `An unauthenticated user`.
      def name
        @name || 'GitLab Orbit Indexer'
      end
    end
  end
end
