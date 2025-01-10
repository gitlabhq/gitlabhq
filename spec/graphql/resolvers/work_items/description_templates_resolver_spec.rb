# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::WorkItems::DescriptionTemplatesResolver, feature_category: :api do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group)        { create(:group, developers: current_user) }

  let_it_be(:template_files) do
    {
      ".gitlab/issue_templates/project_issues_template_a.md" => "project_issues_template_a content",
      ".gitlab/issue_templates/project_issues_template_b.md" => "project_issues_template_b content"
    }
  end

  let_it_be(:project) do
    create(:project, :custom_repo, files: template_files, group: group)
       .tap { |p| group.file_template_project_id = p.id }
  end

  let_it_be(:project_namespace) { project.project_namespace }

  let(:args) { { name: nil } }
  let(:ctx) { { current_user: current_user } }

  subject(:result) do
    resolve(described_class, obj: object, args: args, ctx: ctx,
      field_opts: { calls_gitaly: true })
  end

  shared_examples 'a template description resolver' do
    it 'returns all templates with content' do
      expect(result.items[0])
        .to have_attributes(name: 'project_issues_template_a', content: 'project_issues_template_a content')

      expect(result.items[1])
        .to have_attributes(name: 'project_issues_template_b', content: 'project_issues_template_b content')
    end
  end

  describe '#resolve' do
    context 'when namespace is a group' do
      let(:object) { group }

      it_behaves_like 'a template description resolver'

      context 'without a file template project id' do
        before do
          allow(group).to receive(:file_template_project_id).and_return(nil)
        end

        it { is_expected.to be_empty }
      end
    end

    context 'when namespace is a project' do
      let(:object) { project_namespace }

      it_behaves_like 'a template description resolver'
    end
  end
end
