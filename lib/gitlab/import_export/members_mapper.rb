module Gitlab
  module ImportExport
    class MembersMapper

      attr_reader :map, :note_member_list

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

        @map = generate_map
      end

      def default_project_member
        @default_project_member ||=
          begin
            return @project.project_members.first.user.id unless @project.project_members.empty?
            default_member = ProjectMember.new(default_project_member_hash)
            default_member.save!
            default_member.user.id
          end
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
        member.except('id').merge(source_id: @project.id)
      end

      def default_project_member_hash
        { user: @user, access_level: ProjectMember::MASTER, source_id: @project.id }
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
