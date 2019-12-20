# frozen_string_literal: true

module Gitlab
  module ImportExport
    class MembersMapper
      def initialize(exported_members:, user:, importable:)
        @exported_members = user.admin? ? exported_members : []
        @user = user
        @importable = importable

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
                existing_user = User.where(find_user_query(member)).first
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
        map.has_key?(old_author_id) && map[old_author_id] != default_user_id
      end

      private

      def missing_keys_tracking_hash
        Hash.new do |_, key|
          default_user_id
        end
      end

      def ensure_default_member!
        @importable.members.destroy_all # rubocop: disable DestroyAll

        relation_class.create!(user: @user, access_level: relation_class::MAINTAINER, source_id: @importable.id, importing: true)
      rescue => e
        raise e, "Error adding importer user to #{@importable.class} members. #{e.message}"
      end

      def add_team_member(member, existing_user = nil)
        member['user'] = existing_user

        relation_class.create(member_hash(member)).persisted?
      end

      def member_hash(member)
        parsed_hash(member).merge(
          'source_id' => @importable.id,
          'importing' => true,
          'access_level' => [member['access_level'], relation_class::MAINTAINER].min
        ).except('user_id')
      end

      def parsed_hash(member)
        Gitlab::ImportExport::AttributeCleaner.clean(relation_hash:  member.deep_stringify_keys,
                                                     relation_class: relation_class)
      end

      def find_user_query(member)
        user_arel[:email].eq(member['user']['email']).or(user_arel[:username].eq(member['user']['username']))
      end

      def user_arel
        @user_arel ||= User.arel_table
      end

      def relation_class
        case @importable
        when Project
          ProjectMember
        when Group
          GroupMember
        end
      end
    end
  end
end
