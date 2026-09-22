# frozen_string_literal: true

# User contribution mapping is always enabled for Direct Transfer since it
# went GA in 18.4. This class previously stored the mapping mode as a Redis
# hash field with a 24 h TTL, which an attacker could outlast by returning a
# large Retry-After on a 429 to GetMembersQuery; when the field expired the
# members pipeline silently fell through to the legacy user resolution path
# and rewrote merge_request.author_id to an arbitrary existing user on the
# target instance. See gitlab-org/gitlab#628379.
#
# The class is retained as a shim so callers do not need to change, but the
# flag no longer touches Redis: it is hardcoded to enabled.
module Import
  module BulkImports
    class EphemeralData
      def initialize(bulk_import_id)
        @bulk_import_id = bulk_import_id
      end

      def enable_importer_user_mapping
        # No-op. Kept for backwards compatibility with older callers.
      end

      def importer_user_mapping_enabled?
        true
      end

      private

      attr_reader :bulk_import_id
    end
  end
end
