# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['TerraformStateVersion'] do
  include GraphqlHelpers

  it { expect(described_class.graphql_name).to eq('TerraformStateVersion') }
  it { expect(described_class).to require_graphql_authorizations(:read_terraform_state) }

  describe 'fields' do
    let(:fields) { %i[id created_by_user job download_path serial created_at updated_at] }

    it { expect(described_class).to have_graphql_fields(fields) }

    it { expect(described_class.fields['id'].type).to be_non_null }
    it { expect(described_class.fields['createdByUser'].type).not_to be_non_null }
    it { expect(described_class.fields['job'].type).not_to be_non_null }
    it { expect(described_class.fields['downloadPath'].type).not_to be_non_null }
    it { expect(described_class.fields['serial'].type).not_to be_non_null }
    it { expect(described_class.fields['createdAt'].type).to be_non_null }
    it { expect(described_class.fields['updatedAt'].type).to be_non_null }
  end

  describe 'query' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:terraform_state) { create(:terraform_state, :with_version, :locked, project: project) }

    before do
      project.add_developer(user)
    end

    let(:query) do
      <<~GRAPHQL
        query {
          project(fullPath: "#{project.full_path}") {
            terraformState(name: "#{terraform_state.name}") {
              latestVersion {
                id
                job {
                  name
                }
              }
            }
          }
        }
      GRAPHQL
    end

    subject(:execute) { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    shared_examples 'returning latest version' do
      it 'returns latest version of terraform state' do
        expect(execute.dig('data', 'project', 'terraformState', 'latestVersion')).to match a_graphql_entity_for(
          terraform_state.latest_version
        )
      end
    end

    it_behaves_like 'returning latest version'

    it 'returns job of the latest version' do
      expect(execute.dig('data', 'project', 'terraformState', 'latestVersion', 'job')).to be_present
    end

    context 'when user cannot read jobs' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(user, :read_commit_status, terraform_state.latest_version).and_return(false)
      end

      it_behaves_like 'returning latest version'

      it 'does not return job of the latest version' do
        expect(execute.dig('data', 'project', 'terraformState', 'latestVersion', 'job')).not_to be_present
      end
    end
  end
end
