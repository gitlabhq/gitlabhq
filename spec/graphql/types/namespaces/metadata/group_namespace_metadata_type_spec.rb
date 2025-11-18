# frozen_string_literal: true

require "spec_helper"

RSpec.describe Types::Namespaces::Metadata::GroupNamespaceMetadataType, feature_category: :groups_and_projects do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }

  let(:type_specific_fields) { [:hasProjects] }

  it_behaves_like "expose all metadata fields for the namespace"

  shared_examples "group namespace metadata values" do
    it_behaves_like "common namespace metadata values"

    where(:field, :value) do
      :is_issue_repositioning_disabled | lazy { namespace.root_ancestor.issue_repositioning_disabled? }
      :show_new_work_item | lazy { can?(user, :create_work_item, namespace) }
      :has_projects | lazy { GroupProjectsFinder.new(group: namespace, current_user: user).execute.exists? }
      :group_id | lazy { namespace.id.to_s }
    end

    with_them do
      it "expects to return the right value" do
        expect(resolve_field(field, namespace, current_user: user)).to eq(value)
      end
    end
  end

  context "when fetching public group" do
    let_it_be(:namespace) { create(:group, :public) }

    before_all do
      namespace.add_developer(user)
    end

    it_behaves_like "group namespace metadata values"
  end

  context "when fetching private group" do
    let_it_be(:namespace) { create(:group, :private) }

    context "when user is not member of the group" do
      it_behaves_like "group namespace metadata values"
    end

    context "when user is member of the group" do
      before_all do
        namespace.add_developer(user)
      end

      it_behaves_like "group namespace metadata values"
    end
  end

  describe '#show_new_work_item' do
    let_it_be(:namespace) { create(:group) }
    let_it_be(:developer) { create(:user) }

    before_all do
      namespace.add_developer(developer)
    end

    context 'when user is a member of the namespace' do
      it 'returns false' do
        expect(resolve_field(:show_new_work_item, namespace, current_user: developer)).to be(false)
      end
    end
  end
end
