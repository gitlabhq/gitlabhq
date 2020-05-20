# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::ProjectsResolver do
  include GraphqlHelpers

  describe '#resolve' do
    subject { resolve(described_class, obj: nil, args: filters, ctx: { current_user: current_user }) }

    let_it_be(:project) { create(:project, :public) }
    let_it_be(:other_project) { create(:project, :public) }
    let_it_be(:private_project) { create(:project, :private) }
    let_it_be(:other_private_project) { create(:project, :private) }

    let_it_be(:user) { create(:user) }

    let(:filters) { {} }

    before_all do
      project.add_developer(user)
      private_project.add_developer(user)
    end

    context 'when user is not logged in' do
      let(:current_user) { nil }

      context 'when no filters are applied' do
        it 'returns all public projects' do
          is_expected.to contain_exactly(project, other_project)
        end

        context 'when search filter is provided' do
          let(:filters) { { search: project.name } }

          it 'returns matching project' do
            is_expected.to contain_exactly(project)
          end
        end

        context 'when membership filter is provided' do
          let(:filters) { { membership: true } }

          it 'returns empty list' do
            is_expected.to be_empty
          end
        end
      end
    end

    context 'when user is logged in' do
      let(:current_user) { user }

      context 'when no filters are applied' do
        it 'returns all visible projects for the user' do
          is_expected.to contain_exactly(project, other_project, private_project)
        end

        context 'when search filter is provided' do
          let(:filters) { { search: project.name } }

          it 'returns matching project' do
            is_expected.to contain_exactly(project)
          end
        end

        context 'when membership filter is provided' do
          let(:filters) { { membership: true } }

          it 'returns projects that user is member of' do
            is_expected.to contain_exactly(project, private_project)
          end
        end
      end
    end
  end
end
