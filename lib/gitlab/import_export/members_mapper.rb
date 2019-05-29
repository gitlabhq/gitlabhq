# frozen_string_literal: true

module Gitlab
  module ImportExport
    class MembersMapper
      def initialize(exported_members:, user:, project:)
        @exported_members = user.admin? ? exported_members : []
        @user = user
        @project = project

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

      def include?(old_author_id)
        map.keys.include?(old_author_id) && map[old_author_id] != default_user_id
      end

      private

      def missing_keys_tracking_hash
        Hash.new do |_, key|
          default_user_id
        end
      end

      def ensure_default_member!
        @project.project_members.destroy_all # rubocop: disable DestroyAll

        ProjectMember.create!(user: @user, access_level: ProjectMember::MAINTAINER, source_id: @project.id, importing: true)
      end

      def add_team_member(member, existing_user = nil)
        member['user'] = existing_user

        ProjectMember.create(member_hash(member)).persisted?
      end

      def member_hash(member)
        parsed_hash(member).merge(
          'source_id' => @project.id,
          'importing' => true,
          'access_level' => [member['access_level'], ProjectMember::MAINTAINER].min
        ).except('user_id')
      end

      def parsed_hash(member)
        Gitlab::ImportExport::AttributeCleaner.clean(relation_hash: member.deep_stringify_keys,
                                                     relation_class: ProjectMember)
      end

      def find_project_user_query(member)
        user_arel[:email].eq(member['user']['email']).or(user_arel[:username].eq(member['user']['username']))
      end

      def user_arel
        @user_arel ||= User.arel_table
      end
    end
  end
end
