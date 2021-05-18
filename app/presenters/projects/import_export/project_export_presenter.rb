# frozen_string_literal: true

module Projects
  module ImportExport
    class ProjectExportPresenter < Gitlab::View::Presenter::Delegated
      include ActiveModel::Serializers::JSON

      presents :project

      def project_members
        super + converted_group_members
      end

      def description
        self.respond_to?(:override_description) ? override_description : super
      end

      def protected_branches
        project.exported_protected_branches
      end

      private

      def converted_group_members
        group_members.each do |group_member|
          group_member.source_type = 'Project' # Make group members project members of the future import
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def group_members
        return [] unless current_user.can?(:admin_group, project.group)

        # We need `.connected_to_user` here otherwise when a group has an
        # invitee, it would make the following query return 0 rows since a NULL
        # user_id would be present in the subquery
        # See http://stackoverflow.com/questions/129077/not-in-clause-and-null-values
        non_null_user_ids = project.project_members.connected_to_user.select(:user_id)
        GroupMembersFinder.new(project.group).execute.where.not(user_id: non_null_user_ids)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
