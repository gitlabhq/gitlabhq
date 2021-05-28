# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuablesDescriptionTemplatesHelper, :clean_gitlab_redis_cache do
  include_context 'project issuable templates context'

  describe '#issuable_templates' do
    let_it_be(:inherited_from) { nil }
    let_it_be(:user) { create(:user) }
    let_it_be(:parent_group, reload: true) { create(:group) }
    let_it_be(:project, reload: true) { create(:project, :custom_repo, files: issuable_template_files) }
    let_it_be(:group_member) { create(:group_member, :developer, group: parent_group, user: user) }
    let_it_be(:project_member) { create(:project_member, :developer, user: user, project: project) }

    it 'returns empty hash when template type does not exist' do
      expect(helper.issuable_templates(build(:project), 'non-existent-template-type')).to eq({})
    end

    context 'with cached issuable templates' do
      it 'does not call TemplateFinder' do
        expect(Gitlab::Template::IssueTemplate).to receive(:template_names).once.and_call_original
        expect(Gitlab::Template::MergeRequestTemplate).to receive(:template_names).once.and_call_original

        helper.issuable_templates(project, 'issues')
        helper.issuable_templates(project, 'merge_request')
        helper.issuable_templates(project, 'issues')
        helper.issuable_templates(project, 'merge_request')
      end
    end

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
        let_it_be(:group, reload: true) { create(:group, parent: parent_group) }
        let_it_be(:project, reload: true) { create(:project, :custom_repo, group: group, files: issuable_template_files) }

        before do
          project.update!(group: group)
          parent_group.update_columns(file_template_project_id: file_template_project.id)
        end

        it_behaves_like 'project issuable templates'
      end
    end
  end

  describe '#issuable_templates_names' do
    let_it_be(:project) { build(:project) }

    before do
      allow(helper).to receive(:ref_project).and_return(project)
      allow(helper).to receive(:issuable_templates).and_return(templates)
    end

    context 'with matching project templates' do
      let(:templates) do
        {
          "" => [
            { name: "another_issue_template", id: "another_issue_template", project_id: project.id },
            { name: "custom_issue_template", id: "custom_issue_template", project_id: project.id }
          ],
          "Instance" => [
            { name: "first_issue_issue_template", id: "first_issue_issue_template", project_id: non_existing_record_id },
            { name: "second_instance_issue_template", id: "second_instance_issue_template", project_id: non_existing_record_id }
          ]
        }
      end

      it 'returns project templates only' do
        expect(helper.issuable_templates_names(Issue.new)).to eq(%w[another_issue_template custom_issue_template])
      end
    end

    context 'without matching project templates' do
      let(:templates) do
        {
          "Project Templates" => [
            { name: "another_issue_template", id: "another_issue_template", project_id: non_existing_record_id },
            { name: "custom_issue_template", id: "custom_issue_template", project_id: non_existing_record_id }
          ],
          "Instance" => [
            { name: "first_issue_issue_template", id: "first_issue_issue_template", project_id: non_existing_record_id },
            { name: "second_instance_issue_template", id: "second_instance_issue_template", project_id: non_existing_record_id }
          ]
        }
      end

      it 'returns empty array' do
        expect(helper.issuable_templates_names(Issue.new)).to eq([])
      end
    end

    context 'when there are not templates in the project' do
      let(:templates) { {} }

      it 'returns empty array' do
        expect(helper.issuable_templates_names(Issue.new)).to eq([])
      end
    end
  end
end
