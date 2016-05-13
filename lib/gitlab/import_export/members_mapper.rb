module Gitlab
  module ImportExport
    class MembersMapper

      attr_reader :map, :note_member_list

      def initialize(exported_members:, user:, project_id:)
        @exported_members = exported_members
        @user = user
        @project_id = project_id
        @note_member_list = []

        @project_member_map = Hash.new do |_, key|
          @note_member_list << key
          default_project_member
        end

        @map = generate_map
      end

      private

      def generate_map
        @exported_members.each do |member|
          existing_user = User.where(find_project_user_query(member)).first
          assign_member(existing_user, member) if existing_user
        end
        @project_member_map
      end

      def assign_member(existing_user, member)
        old_user_id = member['user']['id']
        member['user'] = existing_user
        project_member = ProjectMember.new(member_hash(member))
        @project_member_map[old_user_id] = project_member.user.id if project_member.save
      end

      def member_hash(member)
        member.except('id').merge(source_id: @project_id)
      end

      #TODO: If default, then we need to leave a comment 'Comment by <original username>' on comments
      def default_project_member
        @default_project_member ||=
          begin
            default_member = ProjectMember.new(default_project_member_hash)
            default_member.user.id if default_member.save
          end
      end

      def default_project_member_hash
        { user: @user, access_level: ProjectMember::MASTER, source_id: @project_id }
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
