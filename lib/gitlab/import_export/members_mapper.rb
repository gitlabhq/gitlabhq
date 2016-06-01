module Gitlab
  module ImportExport
    class MembersMapper

      attr_reader :note_member_list

      def initialize(exported_members:, user:, project:)
        @exported_members = exported_members
        @user = user
        @project = project
        @note_member_list = []

        # This needs to run first, as second call would be from generate_map
        # which means project members already exist.
        default_project_member

        @project_member_map = Hash.new do |_, key|
          @note_member_list << key
          default_project_member
        end

      end

      def default_project_member
        @default_project_member ||=
          begin
            default_member = ProjectMember.new(default_project_member_hash)
            default_member.create!
            default_member.user.id
          end
      end

      def map
        @map ||=
          begin
            @exported_members.inject(@project_member_map) do |hash, member|
              existing_user = User.where(find_project_user_query(member)).first
              if existing_user
                old_user_id = member['user']['id']
                add_user_as_team_member(existing_user, member)
                hash[old_user_id] = existing_user.id
              end
              hash
            end
          end
      end

      private

      def add_user_as_team_member(existing_user, member)
        member['user'] = existing_user
        ProjectMember.create!(member_hash(member))
      end

      def member_hash(member)
        member.except('id').merge(source_id: @project.id, importing: true)
      end

      def default_project_member_hash
        { user: @user, access_level: ProjectMember::MASTER, source_id: @project.id, importing: true }
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
