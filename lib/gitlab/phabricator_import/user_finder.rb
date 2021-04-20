# frozen_string_literal: true

module Gitlab
  module PhabricatorImport
    class UserFinder
      def initialize(project, phids)
        @project = project
        @phids = phids
        @loaded_phids = Set.new
      end

      def find(phid)
        found_user = object_map.get_gitlab_model(phid) do
          find_user_for_phid(phid)
        end

        loaded_phids << phid

        found_user
      end

      private

      attr_reader :project, :phids, :loaded_phids

      def object_map
        @object_map ||= Gitlab::PhabricatorImport::Cache::Map.new(project)
      end

      def find_user_for_phid(phid)
        phabricator_user = phabricator_users.find { |u| u.phabricator_id == phid }
        return unless phabricator_user

        project.authorized_users.find_by_username(phabricator_user.username)
      end

      def phabricator_users
        @user_responses ||= client.users(users_to_request).flat_map(&:users)
      end

      def users_to_request
        phids - loaded_phids.to_a
      end

      def client
        @client ||=
          Gitlab::PhabricatorImport::Conduit::User
            .new(phabricator_url: project.import_data.data['phabricator_url'],
                 api_token: project.import_data.credentials[:api_token])
      end
    end
  end
end
