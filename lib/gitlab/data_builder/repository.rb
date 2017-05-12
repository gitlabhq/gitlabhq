module Gitlab
  module DataBuilder
    module Repository
      extend self

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
    end
  end
end
