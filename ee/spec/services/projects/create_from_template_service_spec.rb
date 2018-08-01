require 'spec_helper'

describe Projects::CreateFromTemplateService do
  let(:group) { create(:group) }
  let(:project) { create(:project, :public, namespace: group) }
  let(:user) { create(:user) }
  let(:project_name) { project.name }
  let(:use_custom_template) { true }
  let(:project_params) do
    {
      path: user.to_param,
      template_name: project_name,
      description: 'project description',
      visibility_level: Gitlab::VisibilityLevel::PUBLIC,
      use_custom_template: use_custom_template
    }
  end

  subject { described_class.new(user, project_params) }

  before do
    stub_licensed_features(custom_project_templates: true)
    stub_ee_application_setting(custom_project_templates_group_id: group.id)
  end

  context '#execute' do
    context 'does not create project from custom template' do
      after do
        project = subject.execute

        expect(project).to be_saved
        expect(project.repository.empty?).to be true
      end

      context 'when use_custom_template is not present or false' do
        let(:use_custom_template) { false }

        it 'creates an empty project' do
          expect(::Gitlab::ProjectTemplate).to receive(:find)
          expect(subject).not_to receive(:find_template_project)
        end
      end

      context 'when custom_project_templates feature is not enabled' do
        it 'creates an empty project' do
          stub_licensed_features(custom_project_templates: false)

          expect(::Gitlab::ProjectTemplate).to receive(:find)
          expect(subject).not_to receive(:find_template_project)
        end
      end

      context 'when custom_project_template does not exist' do
        let(:project_name) { 'whatever' }

        it 'creates an empty project' do
          expect(::Projects::GitlabProjectsImportService)
            .to receive(:new).with(user, hash_excluding(:custom_template), anything).and_call_original
        end
      end
    end

    context 'creates project from custom template' do
      # If we move the project inside a let block it throws a SEGFAULT error
      before do
        @project = subject.execute
      end

      it 'returns the created project' do
        expect(@project).to be_saved
        expect(@project.import_scheduled?).to be(true)
      end

      context 'the result project' do
        it 'overrides template description' do
          expect(@project.description).to match('project description')
        end

        it 'overrides template visibility_level' do
          expect(@project.visibility_level).to eq(Gitlab::VisibilityLevel::PUBLIC)
        end
      end
    end
  end
end
