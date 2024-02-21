# frozen_string_literal: true

# This file can contain only simple constructs as it is shared between:
# 1. `Pure Ruby`: `bin/audit-event-type`
# 2. `GitLab Rails`: `lib/gitlab/audit/type/definition.rb`

module Gitlab
  module Audit
    module Type
      module Shared
        # The PARAMS in config/audit_events/types/type_schema.json
        PARAMS = %i[
          name
          description
          introduced_by_issue
          introduced_by_mr
          feature_category
          milestone
          saved_to_database
          streamed
          scope
        ].freeze
      end
    end
  end
end
