# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::EnvironmentsResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  context "with a group" do
    let(:group)   { create(:group) }
    let(:project) { create(:project, :public, group: group) }
    let!(:environment1) { create(:environment, name: 'production', project: project) }
    let!(:environment2) { create(:environment, name: 'test', project: project) }
    let!(:environment3) { create(:environment, name: 'test2', project: project) }

    before do
      group.add_developer(current_user)
    end

    describe '#resolve' do
      it 'finds all environments' do
        expect(resolve_environments).to contain_exactly(environment1, environment2, environment3)
      end

      context 'with name' do
        it 'finds a specific environment with name' do
          expect(resolve_environments(name: environment1.name)).to contain_exactly(environment1)
        end
      end

      context 'with search' do
        it 'searches environment by name' do
          expect(resolve_environments(search: 'test')).to contain_exactly(environment2, environment3)
        end

        context 'when the search term does not match any environments' do
          it 'is empty' do
            expect(resolve_environments(search: 'nonsense')).to be_empty
          end
        end
      end

      context 'when project is nil' do
        subject { resolve(described_class, obj: nil, args: {}, ctx: { current_user: current_user }) }

        it { is_expected.to be_nil }
      end
    end
  end

  def resolve_environments(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: project, args: args, ctx: context)
  end
end
