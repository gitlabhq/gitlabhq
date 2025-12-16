# frozen_string_literal: true

require "spec_helper"

RSpec.describe Types::Namespaces::Metadata::UserNamespaceMetadataType, feature_category: :groups_and_projects do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  it_behaves_like 'expose all metadata fields for the namespace'

  context "when fetching user namespace" do
    let_it_be(:user) { create(:user) }
    let_it_be(:namespace) { user.namespace }

    it_behaves_like "common namespace metadata values"

    where(:field, :value) do
      :is_issue_repositioning_disabled | false
      :show_new_work_item | false
      :group_id | nil
    end

    with_them do
      it { expect(resolve_field(field, namespace, current_user: user)).to eq(value) }
    end
  end
end
