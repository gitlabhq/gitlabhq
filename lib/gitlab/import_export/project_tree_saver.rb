# frozen_string_literal: true

module Gitlab
  module ImportExport
    class ProjectTreeSaver
      attr_reader :full_path

      def initialize(project:, current_user:, shared:, params: {})
        @params       = params
        @project      = project
        @current_user = current_user
        @shared       = shared
        @full_path    = File.join(@shared.export_path, ImportExport.project_filename)
      end

      def save
        project_tree = tree_saver.serialize(@project, reader.project_tree)
        fix_project_tree(project_tree)
        tree_saver.save(project_tree, @shared.export_path, ImportExport.project_filename)

        true
      rescue => e
        @shared.error(e)
        false
      end

      private

      # Aware that the resulting hash needs to be pure-hash and
      # does not include any AR objects anymore, only objects that run `.to_json`
      def fix_project_tree(project_tree)
        if @params[:description].present?
          project_tree['description'] = @params[:description]
        end

        project_tree['project_members'] += group_members_array

        RelationRenameService.add_new_associations(project_tree)
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

      def tree_saver
        @tree_saver ||= RelationTreeSaver.new
      end
    end
  end
end
