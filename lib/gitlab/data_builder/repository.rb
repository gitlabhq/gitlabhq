# frozen_string_literal: true

module Gitlab
  module DataBuilder
    module Repository
      extend self

      SAMPLE_DATA = {
        event_name: 'repository_update',
        user_id: 10,
        user_name: 'john.doe',
        user_email: 'test@example.com',
        user_avatar: 'http://example.com/avatar/user.png',
        project_id: 40,
        changes: [
          {
            before: "8205ea8d81ce0c6b90fbe8280d118cc9fdad6130",
            after: "4045ea7a3df38697b3730a20fb73c8bed8a3e69e",
            ref: "refs/heads/master"
          }
        ],
        refs: ["refs/heads/master"]
      }.freeze

      # Produce a hash of post-receive data
      def update(project, user, changes, refs)
        {
          event_name: 'repository_update',

          user_id: user.id,
          user_name: user.name,
          user_email: user.email,
          user_avatar: user.avatar_url,

          project_id: project.id,
          project: project.hook_attrs,

          changes: changes,

          refs: refs
        }
      end

      # Produce a hash of partial data for a single change
      def single_change(oldrev, newrev, ref)
        {
          before: oldrev,
          after: newrev,
          ref: ref
        }
      end

      def sample_data
        SAMPLE_DATA
      end
    end
  end
end
