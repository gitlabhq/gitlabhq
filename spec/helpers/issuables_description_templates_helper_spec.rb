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
    end
  end

  describe '#selected_template' do
    let_it_be(:project) { build(:project) }

    before do
      allow(helper).to receive(:ref_project).and_return(project)
      allow(helper).to receive(:issuable_templates).and_return(templates)
    end

    context 'with project templates' do
      let(:templates) do
        {
          "" => [
            { name: "another_issue_template", id: "another_issue_template", project_id: project.id },
            { name: "custom_issue_template", id: "custom_issue_template", project_id: project.id }
          ]
        }
      end

      it 'returns project templates' do
        value = [
            "",
            [
              { name: "another_issue_template", id: "another_issue_template", project_id: project.id },
              { name: "custom_issue_template", id: "custom_issue_template", project_id: project.id }
            ]
          ].to_json
        expect(helper.available_service_desk_templates_for(@project)).to eq(value)
      end
    end

    context 'when there are not templates in the project' do
      let(:templates) { {} }

      it 'returns empty array' do
        value = [].to_json
        expect(helper.available_service_desk_templates_for(@project)).to eq(value)
      end
    end
  end
end
