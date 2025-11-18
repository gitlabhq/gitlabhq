# frozen_string_literal: true

require "spec_helper"

RSpec.describe Types::Namespaces::Metadata::ProjectNamespaceMetadataType, feature_category: :groups_and_projects do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, group: group) }
  let_it_be(:namespace) { project.project_namespace }

  it_behaves_like "expose all metadata fields for the namespace"

  shared_examples "project namespace metadata values" do
    it_behaves_like "common namespace metadata values"

    where(:field, :value) do
      :default_branch | lazy { project.default_branch_or_main }
      :is_issue_repositioning_disabled | lazy { project.root_namespace.issue_repositioning_disabled? }
      :group_id | lazy { project.group&.id&.to_s }
    end

    with_them do
      it { expect(resolve_field(field, namespace, current_user: user)).to eq(value) }
    end
  end

  context "when fetching a project" do
    it_behaves_like "project namespace metadata values"
  end

  describe '#show_new_work_item' do
    context 'when project is archived' do
      before do
        project.update!(archived: true)
      end

      it 'returns false' do
        expect(resolve_field(:show_new_work_item, namespace, current_user: user)).to be(false)
      end
    end

    context 'when user is not signed in' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
      end

      it 'returns true for public projects' do
        expect(resolve_field(:show_new_work_item, namespace, current_user: nil)).to be(true)
      end
    end

    context 'when user can create work items' do
      let_it_be(:developer) { create(:user) }

      before_all do
        project.add_developer(developer)
      end

      it 'returns true' do
        expect(resolve_field(:show_new_work_item, namespace, current_user: developer)).to be(true)
      end
    end

    context 'when user cannot create work items' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it 'returns false' do
        expect(resolve_field(:show_new_work_item, namespace, current_user: user)).to be(false)
      end
    end
  end

  describe '#default_branch' do
    context 'when project has a default branch' do
      before do
        allow(project).to receive(:default_branch_or_main).and_return('main')
      end

      it 'returns the default branch' do
        expect(resolve_field(:default_branch, namespace, current_user: user)).to eq('main')
      end
    end

    context 'when project has no default branch' do
      before do
        allow(project).to receive(:default_branch_or_main).and_return(nil)
      end

      it 'returns nil' do
        expect(resolve_field(:default_branch, namespace, current_user: user)).to be_nil
      end
    end
  end

  describe '#group_id' do
    context 'when project belongs to a group' do
      it 'returns the group id as string' do
        expect(resolve_field(:group_id, namespace, current_user: user)).to eq(group.id.to_s)
      end
    end

    context 'when project is a user personal project' do
      let_it_be(:personal_project) { create(:project, :in_user_namespace) }
      let_it_be(:namespace) { personal_project.project_namespace }

      it 'returns nil' do
        expect(resolve_field(:group_id, namespace, current_user: user)).to be_nil
      end
    end
  end
end
