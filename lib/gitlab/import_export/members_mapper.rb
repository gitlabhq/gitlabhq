module Gitlab
  module ImportExport
    class MembersMapper
      attr_reader :missing_author_ids

      def initialize(exported_members:, user:, project:)
        @exported_members = exported_members
        @user = user
        @project = project
        @missing_author_ids = []

        # This needs to run first, as second call would be from #map
        # which means project members already exist.
        ensure_default_member!
      end

      def map
        @map ||=
          begin
            @exported_members.inject(missing_keys_tracking_hash) do |hash, member|
              if member['user']
                old_user_id = member['user']['id']
                existing_user = User.where(find_project_user_query(member)).first
                hash[old_user_id] = existing_user.id if existing_user && add_team_member(member, existing_user)
              else
                add_team_member(member)
              end

              hash
            end
          end
      end

      def default_user_id
        @user.id
      end

      private

      def missing_keys_tracking_hash
        Hash.new do |_, key|
          @missing_author_ids << key
          default_user_id
        end
      end

      def ensure_default_member!
        ProjectMember.create!(user: @user, access_level: ProjectMember::MASTER, source_id: @project.id, importing: true)
      end

      def add_team_member(member, existing_user = nil)
        member['user'] = existing_user

        ProjectMember.create(member_hash(member)).persisted?
      end

      def member_hash(member)
        member.except('id').merge(source_id: @project.id, importing: true)
      end

      def find_project_user_query(member)
        user_arel[:username].eq(member['user']['username']).or(user_arel[:email].eq(member['user']['email']))
      end

      def user_arel
        @user_arel ||= User.arel_table
      end
    end
  end
end
