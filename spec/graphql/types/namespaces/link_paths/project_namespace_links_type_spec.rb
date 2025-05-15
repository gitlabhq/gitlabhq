# frozen_string_literal: true

require "spec_helper"

RSpec.describe Types::Namespaces::LinkPaths::ProjectNamespaceLinksType, feature_category: :shared do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }

  subject(:type) { described_class.resolve_type(namespace, {}) }

  it_behaves_like "expose all link paths fields for the namespace"

  shared_examples "project namespace link paths values" do
    it_behaves_like "common namespace link paths values"

    where(:field, :value) do
      :issues_list | lazy { "/#{namespace.full_path}/-/issues" }
      :labels_manage | lazy { "/#{namespace.full_path}/-/labels" }
      :new_project | lazy { "/projects/new?namespace_id=#{group.id}" }
      :new_comment_template | "/-/profile/comment_templates"
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
end
