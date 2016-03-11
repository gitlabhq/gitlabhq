module Projects
  module ImportExport
    class MembersMapper

      def self.map(*args)
        new(*args).map
      end

      def initialize(exported_members:, user:, project_id:)
        @exported_members = exported_members
        @user = user
        @project_id = project_id
      end

      def map
        @project_member_map ||= project_member_map
      end

      private

      def project_member_map
        @project_member_map = Hash.new(default_project_member)
        @exported_members.each do |member|
          existing_user = User.where(find_project_user_query(member)).first
          assign_member(existing_user, member) if existing_user
        end
        @project_member_map
      end

      def assign_member(existing_user, member)
        member['user'] = existing_user
        project_member = ProjectMember.new(member_hash(member))
        @project_member_map[existing_user.id] = project_member if project_member.save
      end

      def member_hash(member)
        member.except('id').merge(source_id: @project_id)
      end

      #TODO: If default, then we need to leave a comment 'Comment by <original username>' on comments
      def default_project_member
        @default_project_member ||=
          begin
            default_member = ProjectMember.new(default_project_member_hash)
            default_member if default_member.save
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
