# frozen_string_literal: true

require "spec_helper"

RSpec.describe Types::Namespaces::LinkPaths::UserNamespaceLinksType, feature_category: :shared do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  it_behaves_like 'expose all link paths fields for the namespace'

  context "when fetching user namespace" do
    let_it_be(:user) { create(:user, :notification_email) }
    let_it_be(:namespace) { user.namespace }

    it_behaves_like "common namespace link paths values"

    where(:field, :value) do
      :user_export_email | nil
      :new_trial_path | nil
    end

    with_them do
      it { expect(resolve_field(field, namespace, current_user: user)).to eq(value) }
    end
  end
end
