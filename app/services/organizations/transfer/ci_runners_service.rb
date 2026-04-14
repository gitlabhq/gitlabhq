# frozen_string_literal: true

module Organizations
  module Transfer
    class CiRunnersService
      include Organizations::Transfer::Concerns::OrganizationUpdater

      def initialize(group:, old_organization:, new_organization:)
        @group = group
        @old_organization = old_organization
        @new_organization = new_organization
      end

      def execute
        group_ids = Ci::NamespaceMirror.by_group_and_descendants(group.id).select(:namespace_id)
        project_ids = Ci::ProjectMirror.by_namespace_id(group_ids).select(:project_id)

        group_runners = Ci::Runner.belonging_to_group(group_ids)
        project_runners = Ci::Runner.belonging_to_project(project_ids)

        transfer_runners(group_runners)
        transfer_runners(project_runners)
      end

      private

      attr_reader :group, :old_organization, :new_organization

      def transfer_runners(runners)
        update_organization_id_for(Ci::Runner) { |rel| rel.id_in(runners) }
        update_organization_id_for(Ci::RunnerManager) { |rel| rel.for_runner(runners) }
        update_organization_id_for(Ci::RunnerTagging) { |rel| rel.for_runner(runners) }
      end
    end
  end
end
