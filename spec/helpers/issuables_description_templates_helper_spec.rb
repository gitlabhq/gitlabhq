# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuablesDescriptionTemplatesHelper do
  include_context 'project issuable templates context'

  describe '#issuable_templates' do
    let_it_be(:inherited_from) { nil }
    let_it_be(:user) { create(:user) }
    let_it_be(:parent_group) { create(:group) }
    let_it_be(:project) { create(:project, :custom_repo, files: issuable_template_files) }
    let_it_be(:group_member) { create(:group_member, :developer, group: parent_group, user: user) }
    let_it_be(:project_member) { create(:project_member, :developer, user: user, project: project) }

    context 'when project has no parent group' do
      it_behaves_like 'project issuable templates'
    end

    context 'when project has parent group' do
      before do
        project.update!(group: parent_group)
      end

      context 'when project parent group does not have a file template project' do
        it_behaves_like 'project issuable templates'
      end

      context 'when project parent group has a file template project' do
        let_it_be(:file_template_project) { create(:project, :custom_repo, group: parent_group, files: issuable_template_files) }
        let_it_be(:group) { create(:group, parent: parent_group) }
        let_it_be(:project) { create(:project, :custom_repo, group: group, files: issuable_template_files) }

        before do
          project.update!(group: group)
          parent_group.update_columns(file_template_project_id: file_template_project.id)
        end

        it_behaves_like 'project issuable templates'
      end
    end
  end
end
