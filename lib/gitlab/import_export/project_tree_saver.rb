module Gitlab
  module ImportExport
    class ProjectTreeSaver
      include Gitlab::ImportExport::CommandLineUtil

      attr_reader :full_path

      def initialize(project:, current_user:, shared:)
        @project = project
        @current_user = current_user
        @shared = shared
        @full_path = File.join(@shared.export_path, ImportExport.project_filename)
      end

      def save
        mkdir_p(@shared.export_path)

        File.write(full_path, project_json_tree)
        true
      rescue => e
        @shared.error(e)
        false
      end

      private

      def project_json_tree
        project_json['project_members'] += group_members_json

        project_json.to_json
      end

      def project_json
        @project_json ||= @project.as_json(reader.project_tree)
      end

      def reader
        @reader ||= Gitlab::ImportExport::Reader.new(shared: @shared)
      end

      def group_members_json
        group_members.as_json(reader.group_members_tree).each do |group_member|
          group_member['source_type'] = 'Project' # Make group members project members of the future import
        end
      end

      def group_members
        return [] unless @current_user.can?(:admin_group, @project.group)

        MembersFinder.new(@project.project_members, @project.group).execute(@current_user)
      end
    end
  end
end
