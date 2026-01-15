# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountUsersWithoutGroupOrProjectMembershipMetric < DatabaseMetric
          operation :count

          start { User.active.minimum(:id) }
          finish { User.active.maximum(:id) }

          relation do
            members = Member.where('members.user_id = users.id').select(1)

            User.active.where('NOT EXISTS (?)', members)
          end
        end
      end
    end
  end
end
