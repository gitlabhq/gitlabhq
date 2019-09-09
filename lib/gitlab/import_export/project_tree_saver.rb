# frozen_string_literal: true

module Gitlab
  module ImportExport
    class ProjectTreeSaver
      include Gitlab::ImportExport::CommandLineUtil

      attr_reader :full_path

      def initialize(project:, current_user:, shared:, params: {})
        @params = params
        @project = project
        @current_user = current_user
        @shared = shared
        @full_path = File.join(@shared.export_path, ImportExport.project_filename)
      end

      def save
        mkdir_p(@shared.export_path)

        project_tree = serialize_project_tree
        fix_project_tree(project_tree)
        File.write(full_path, project_tree.to_json)

        true
      rescue => e
        @shared.error(e)
        false
      end

      private

      def fix_project_tree(project_tree)
        if @params[:description].present?
          project_tree['description'] = @params[:description]
        end

        project_tree['project_members'] += group_members_array

        RelationRenameService.add_new_associations(project_tree)
      end

      def serialize_project_tree
        if Feature.enabled?(:export_fast_serialize, default_enabled: true)
          Gitlab::ImportExport::FastHashSerializer
            .new(@project, reader.project_tree)
            .execute
        else
          @project.as_json(reader.project_tree)
        end
      end

      def reader
        @reader ||= Gitlab::ImportExport::Reader.new(shared: @shared)
      end

      def group_members_array
        group_members.as_json(reader.group_members_tree).each do |group_member|
          group_member['source_type'] = 'Project' # Make group members project members of the future import
        end
      end

      def group_members
        return [] unless @current_user.can?(:admin_group, @project.group)

        # We need `.where.not(user_id: nil)` here otherwise when a group has an
        # invitee, it would make the following query return 0 rows since a NULL
        # user_id would be present in the subquery
        # See http://stackoverflow.com/questions/129077/not-in-clause-and-null-values
        non_null_user_ids = @project.project_members.where.not(user_id: nil).select(:user_id)

        GroupMembersFinder.new(@project.group).execute.where.not(user_id: non_null_user_ids)
      end
    end
  end
end
