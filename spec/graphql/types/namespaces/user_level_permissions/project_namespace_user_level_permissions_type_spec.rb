# frozen_string_literal: true

require "spec_helper"

RSpec.describe Types::Namespaces::UserLevelPermissions::ProjectNamespaceUserLevelPermissionsType, feature_category: :shared do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:project_namespace) { project.project_namespace }

  subject(:type) { described_class.resolve_type(project_namespace, {}) }

  it_behaves_like 'expose all user permissions fields for the namespace'

  describe "permission values" do
    let_it_be(:non_member) { create(:user) }
    let_it_be(:guest) { create(:user) }
    let_it_be(:developer) { create(:user) }
    let_it_be(:maintainer) { create(:user) }
    let_it_be(:owner) { create(:user) }

    before_all do
      project.add_guest(guest)
      project.add_developer(developer)
      project.add_maintainer(maintainer)
      project.add_owner(owner)
    end

    # Test the implemented method that returns actual permission values
    context "for can_admin_label permission" do
      where(:user_role, :expected) do
        :non_member | false
        :guest      | false
        :developer  | true
        :maintainer | true
        :owner      | true
      end

      with_them do
        let(:current_user) { send(user_role) }

        it "returns the correct permission value" do
          actual = resolve_field(:can_admin_label, project_namespace, current_user: current_user)

          expect(actual).to eq(expected)
        end
      end
    end

    # Unified test for all non-implemented permissions that return nil
    context "for non-implemented permissions" do
      let(:current_user) { maintainer }

      it "returns nil for can_create_projects" do
        expect(resolve_field(:can_create_projects, project_namespace, current_user: current_user)).to be(false)
      end

      if Gitlab.ee?
        it "returns nil for can_bulk_edit_epics" do
          expect(resolve_field(:can_bulk_edit_epics, project_namespace, current_user: current_user)).to be(false)
        end

        it "returns nil for can_create_epic" do
          expect(resolve_field(:can_create_epic, project_namespace, current_user: current_user)).to be(false)
        end
      end
    end
  end

  context "when project settings restrict permissions" do
    context "when label administration is restricted" do
      before do
        allow_next_instance_of(Ability) do |instance|
          allow(instance).to receive(:can?).with(:admin_label, project).and_return(false)
        end
      end

      it "returns false" do
        expect(resolve_field(:can_admin_label, project_namespace, current_user: user)).to be(false)
      end
    end
  end
end
