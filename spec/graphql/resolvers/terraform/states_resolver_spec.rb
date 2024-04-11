# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Terraform::StatesResolver do
  include GraphqlHelpers

  it { expect(described_class).to have_nullable_graphql_type(Types::Terraform::StateType.connection_type) }
  it { expect(described_class.null).to be_truthy }

  describe '#resolve' do
    let_it_be(:project) { create(:project) }

    let_it_be(:production_state) { create(:terraform_state, project: project) }
    let_it_be(:staging_state) { create(:terraform_state, project: project) }
    let_it_be(:other_state) { create(:terraform_state) }

    let(:ctx) { Hash(current_user: user) }
    let(:user) { create(:user, developer_of: project) }

    subject { resolve(described_class, obj: project, ctx: ctx) }

    it 'returns states associated with the agent' do
      expect(subject).to contain_exactly(production_state, staging_state)
    end

    context 'user does not have permission' do
      let(:user) { create(:user) }

      it { is_expected.to be_empty }
    end
  end
end

RSpec.describe Resolvers::Terraform::StatesResolver.single do
  it { expect(described_class).to be < Resolvers::Terraform::StatesResolver }

  describe 'arguments' do
    subject { described_class.arguments[argument] }

    describe 'name' do
      let(:argument) { 'name' }

      it do
        expect(subject).to be_present
        expect(subject.type).to be_kind_of GraphQL::Schema::NonNull
        expect(subject.type.unwrap).to eq GraphQL::Types::String
        expect(subject.description).to be_present
      end
    end
  end
end
