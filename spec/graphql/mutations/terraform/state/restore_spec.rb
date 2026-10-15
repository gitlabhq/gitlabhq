# frozen_string_literal: true

require 'spec_helper'
RSpec.describe Mutations::Terraform::State::Restore, feature_category: :infrastructure_as_code do
  include GraphqlHelpers
  let_it_be(:project) { create(:project) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:state) do
    create(:terraform_state, project: project, deleted_at: Time.current)
  end

  let(:current_user) { maintainer }
  let(:mutation) do
    described_class.new(
      object: double,
      context: query_context,
      field: double
    )
  end

  before_all do
    project.add_maintainer(maintainer)
    project.add_developer(developer)
  end

  it 'has the expected GraphQL name' do
    expect(described_class.graphql_name).to eq('TerraformStateRestore')
  end

  it 'requires the restore Terraform state permission' do
    expect(described_class).to require_graphql_authorizations(:restore_terraform_state)
  end

  context 'when the user is not authorized' do
    let(:current_user) { developer }

    it 'raises a resource-not-available error' do
      expect { mutation.resolve(id: state.to_global_id) }
        .to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end
  end
end
