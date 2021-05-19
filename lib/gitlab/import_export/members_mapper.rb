# frozen_string_literal: true

module Gitlab
  module ImportExport
    class MembersMapper
      def initialize(exported_members:, user:, importable:)
        @exported_members = user.admin? ? exported_members : []
        @user = user
        @importable = importable

        # This needs to run first, as second call would be from #map
        # which means Project/Group members already exist.
        ensure_default_member!
      end

      def map
        @map ||=
          begin
            @exported_members.inject(missing_keys_tracking_hash) do |hash, member|
              if member['user']
                old_user_id = member['user']['id']
                existing_user = User.find_by(find_user_query(member))
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

      def include?(old_user_id)
        map.has_key?(old_user_id)
      end

      private

      def missing_keys_tracking_hash
        Hash.new do |_, key|
          default_user_id
        end
      end

      def ensure_default_member!
        return if user_already_member?

        @importable.members.destroy_all # rubocop: disable Cop/DestroyAll

        relation_class.create!(user: @user, access_level: highest_access_level, source_id: @importable.id, importing: true)
      rescue StandardError => e
        raise e, "Error adding importer user to #{@importable.class} members. #{e.message}"
      end

      def user_already_member?
        member = @importable.members&.first

        member&.user == @user && member.access_level >= highest_access_level
      end

      def add_team_member(member, existing_user = nil)
        return true if existing_user && @importable.members.exists?(user_id: existing_user.id)

        member['user'] = existing_user
        member_hash = member_hash(member)

        member = relation_class.create(member_hash)

        if member.persisted?
          log_member_addition(member_hash)

          true
        else
          log_member_addition_failure(member_hash, member.errors.full_messages)

          false
        end
      end

      def member_hash(member)
        parsed_hash(member).merge(
          'source_id' => @importable.id,
          'importing' => true,
          'access_level' => [member['access_level'], highest_access_level].min
        ).except('user_id')
      end

      def parsed_hash(member)
        Gitlab::ImportExport::AttributeCleaner.clean(relation_hash:  member.deep_stringify_keys,
                                                     relation_class: relation_class)
      end

      def find_user_query(member)
        user_arel[:email].eq(member['user']['email'])
      end

      def user_arel
        @user_arel ||= User.arel_table
      end

      def relation_class
        case @importable
        when ::Project
          ProjectMember
        when ::Group
          GroupMember
        end
      end

      def highest_access_level
        return relation_class::OWNER if relation_class == GroupMember

        relation_class::MAINTAINER
      end

      def log_member_addition(member_hash)
        log_params = base_log_params(member_hash)
        log_params[:message] = '[Project/Group Import] Added new member'

        logger.info(log_params)
      end

      def log_member_addition_failure(member_hash, errors)
        log_params = base_log_params(member_hash)
        log_params[:message] = "[Project/Group Import] Member addition failed: #{errors&.join(', ')}"

        logger.info(log_params)
      end

      def base_log_params(member_hash)
        {
          user_id: member_hash['user']&.id,
          access_level: member_hash['access_level'],
          importable_type: @importable.class.to_s,
          importable_id: @importable.id,
          root_namespace_id: @importable.try(:root_ancestor)&.id
        }
      end

      def logger
        @logger ||= Gitlab::Import::Logger.build
      end
    end
  end
end
