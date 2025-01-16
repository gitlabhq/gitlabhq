# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuablesDescriptionTemplatesHelper, :clean_gitlab_redis_cache do
  describe '#issuable_templates' do
    include_context 'project issuable templates context'

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

  describe '#available_service_desk_templates_for' do
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

    context 'when there are no templates in the project' do
      let(:templates) { {} }

      it 'returns empty array' do
        value = [].to_json
        expect(helper.available_service_desk_templates_for(@project)).to eq(value)
      end
    end
  end

  describe '#selected_template_name' do
    let(:template_names) { ['another_issue_template', 'custom_issue_template', 'Bug Report Template'] }

    context 'when no issuable_template parameter is provided' do
      it 'does not select a template' do
        expect(helper.selected_template_name(template_names)).to be_nil
      end
    end

    context 'when an issuable_template parameter has been provided' do
      before do
        allow(helper).to receive(:params).and_return({ issuable_template: template_param_value })
      end

      context 'when param matches existing templates' do
        let(:template_param_value) { 'another_issue_template' }

        it 'returns the matching issuable template' do
          expect(helper.selected_template_name(template_names)).to eq('another_issue_template')
        end
      end

      context 'when param does not match any templates' do
        let(:template_param_value) { 'non_matching_issue_template' }

        it 'returns nil' do
          expect(helper.selected_template_name(template_names)).to be_nil
        end
      end

      context 'when param is URL-encoded' do
        let(:template_param_value) { 'Bug%20Report%20Template' }

        it 'returns the matching template name' do
          expect(helper.selected_template_name(template_names)).to eq('Bug Report Template')
        end
      end
    end
  end

  describe '#default_template_name' do
    context 'when a default template is available' do
      let(:template_names) { %w[another_issue_template deFault] }

      it 'returns the default template' do
        issue = build(:issue)

        expect(helper.default_template_name(template_names, issue)).to be('deFault')
      end

      it 'returns nil when issuable has a description set' do
        issue = build(:issue, description: 'from template in project settings')

        expect(helper.default_template_name(template_names, issue)).to be_nil
      end

      it 'returns nil when issuable is persisted' do
        issue = create(:issue)

        expect(helper.default_template_name(template_names, issue)).to be_nil
      end
    end

    context 'when there is no default template' do
      let(:template_names) { %w[another_issue_template] }

      it 'returns nil' do
        expect(helper.default_template_name(template_names, build(:issue))).to be_nil
      end
    end
  end

  describe '#template_names' do
    let(:project) { build(:project) }
    let(:templates) do
      {
        "Project templates" => [
          { name: "another_issue_template", id: "another_issue_template", project_id: project.id },
          { name: "custom_issue_template", id: "custom_issue_template", project_id: project.id },
          { name: "Bug Report Template", id: "Bug Report Template", project_id: project.id }
        ],
        "Group templates" => [
          { name: "another_issue_template", id: "another_issue_template", project_id: project.id }
        ]
      }
    end

    before do
      allow(helper).to receive(:ref_project).and_return(project)
      allow(helper).to receive(:issuable_templates).and_return(templates)
    end

    it 'returns unique list of template names' do
      expect(helper.template_names(build(:issue))).to contain_exactly(
        'another_issue_template',
        'custom_issue_template',
        'Bug Report Template'
      )
    end
  end
end
