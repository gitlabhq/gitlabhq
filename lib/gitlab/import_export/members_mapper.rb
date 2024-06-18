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
          @exported_members.each_with_object(missing_keys_tracking_hash) do |member, hash|
            if member['user']
              old_user_id = member['user']['id']
              existing_user_id = existing_users_email_map[get_email(member)]
              hash[old_user_id] = existing_user_id if existing_user_id && add_team_member(member, existing_user_id)
            else
              add_team_member(member)
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

        relation_class.create!(user: @user, access_level: importer_access_level, source_id: @importable.id, importing: true)
      rescue StandardError => e
        raise e, "Error adding importer user to #{@importable.class} members. #{e.message}"
      end

      def importer_access_level
        if @importable.parent.is_a?(::Group) && !@user.admin?
          lvl = @importable.parent.max_member_access_for_user(@user, only_concrete_membership: true)
          [lvl, highest_access_level].min
        else
          highest_access_level
        end
      end

      def user_already_member?
        member = @importable.members&.first

        member&.user == @user && member.access_level >= highest_access_level
      end

      # Returns {email => user_id} hash where user_id is an ID at current instance
      def existing_users_email_map
        @existing_users_email_map ||= begin
          emails = @exported_members.map { |member| get_email(member) }

          User.by_user_email(emails).pluck(:email, :id).to_h
        end
      end

      # Returns {user_id => email} hash where user_id is an ID at source "old" instance
      def exported_members_email_map
        @exported_members_email_map ||= begin
          result = {}
          @exported_members.each do |member|
            email = get_email(member)

            next unless email

            result[member.dig('user', 'id')] = email
          end

          result
        end
      end

      def get_email(member_data)
        return unless member_data['user']

        member_data.dig('user', 'public_email') || member_data.dig('user', 'email')
      end

      def add_team_member(member, existing_user_id = nil)
        return true if existing_user_id && @importable.members.exists?(user_id: existing_user_id)

        member_hash = member_hash(member)
        if existing_user_id
          member_hash.delete('user')
          member_hash['user_id'] = existing_user_id
        end

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
        result = parsed_hash(member).merge(
          'source_id' => @importable.id,
          'importing' => true,
          'access_level' => [member['access_level'], highest_access_level].min
        ).except('user_id')

        if result['created_by_id']
          created_by_email = exported_members_email_map[result['created_by_id']]

          result['created_by_id'] = existing_users_email_map[created_by_email]
        end

        result
      end

      def parsed_hash(member)
        Gitlab::ImportExport::AttributeCleaner.clean(relation_hash: member.deep_stringify_keys,
          relation_class: relation_class)
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
          user_id: member_hash['user_id'],
          access_level: member_hash['access_level'],
          importable_type: @importable.class.to_s,
          importable_id: @importable.id,
          root_namespace_id: @importable.try(:root_ancestor)&.id
        }
      end

      def logger
        @logger ||= ::Import::Framework::Logger.build
      end
    end
  end
end
