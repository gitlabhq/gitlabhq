# frozen_string_literal: true

require "spec_helper"

RSpec.describe Types::Namespaces::LinkPaths::ProjectNamespaceLinksType, feature_category: :shared do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user, :notification_email) }

  subject(:type) { described_class.resolve_type(namespace, {}) }

  it_behaves_like "expose all link paths fields for the namespace" do
    let(:type_specific_fields) { %i[newWorkItemEmailAddress releasesPath projectImportJiraPath] }
  end

  shared_examples "project namespace link paths values" do
    before do
      stub_incoming_email_setting(enabled: true, address: 'incoming+%{key}@localhost.com')
    end

    it_behaves_like "common namespace link paths values"

    where(:field, :value) do
      :issues_list | lazy { "/#{namespace.full_path}/-/issues" }
      :labels_manage | lazy { "/#{namespace.full_path}/-/labels" }
      :new_project | lazy { "/projects/new?namespace_id=#{group.id}" }
      :new_comment_template | [{ href: "/-/profile/comment_templates", text: "Your comment templates" }]
      :contribution_guide_path | nil
      :new_work_item_email_address | lazy do
        "incoming+#{namespace.project.full_path_slug}-#{namespace.project.id}-" \
          "#{user.incoming_email_token}-issue@localhost.com"
      end
      :user_export_email | lazy { user.notification_email_or_default }
      :releases_path | lazy { "/#{namespace.full_path}/-/releases" }
      :project_import_jira_path | lazy { "/#{namespace.full_path}/-/import/jira" }
    end

    with_them do
      it { expect(resolve_field(field, namespace, current_user: user)).to eq(value) }
    end
  end

  context "when fetching public project" do
    let_it_be(:group) { create(:group, :nested, :public) }
    let_it_be(:project) { create(:project, :public, group: group) }
    let_it_be(:namespace) { project.project_namespace }

    it_behaves_like "project namespace link paths values"
  end

  context "when fetching private project" do
    let_it_be(:group) { create(:group, :nested, :private) }
    let_it_be(:project) { create(:project, :private, group: group) }
    let_it_be(:namespace) { project.project_namespace }

    context "when user is not a member of the project" do
      it_behaves_like "project namespace link paths values"
    end

    context "when user is a member of the project" do
      before_all do
        project.add_developer(user)
      end

      it_behaves_like "project namespace link paths values"
    end
  end

  describe '#contribution_guide_path' do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:project) { create(:project, :public, group: group) }
    let_it_be(:namespace) { project.project_namespace }

    context 'when contribution guide exists' do
      before do
        contribution_guide = instance_double(Gitlab::Git::Tree, name: 'CONTRIBUTING.md')
        allow(project.repository).to receive(:contribution_guide).and_return(contribution_guide)
        allow(project).to receive(:default_branch).and_return('main')
      end

      it 'returns the contribution guide path' do
        expected_path = "/#{project.full_path}/-/blob/main/CONTRIBUTING.md"

        expect(resolve_field(:contribution_guide_path, namespace, current_user: user)).to eq(expected_path)
      end
    end

    context 'when contribution guide does not exist' do
      before do
        allow(project.repository).to receive(:contribution_guide).and_return(nil)
      end

      it 'returns nil' do
        expect(resolve_field(:contribution_guide_path, namespace, current_user: user)).to be_nil
      end
    end

    context 'when project does not exist' do
      let(:namespace) { build(:project_namespace) }

      before do
        allow(namespace).to receive(:project).and_return(nil)
      end

      it 'returns nil' do
        expect(resolve_field(:contribution_guide_path, namespace, current_user: user)).to be_nil
      end
    end

    context 'when repository does not exist' do
      before do
        allow(project).to receive(:repository).and_return(nil)
      end

      it 'returns nil' do
        expect(resolve_field(:contribution_guide_path, namespace, current_user: user)).to be_nil
      end
    end
  end
end
