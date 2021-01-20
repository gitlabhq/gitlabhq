# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ProjectsResolver do
  include GraphqlHelpers

  describe '#resolve' do
    subject { resolve(described_class, obj: nil, args: filters, ctx: { current_user: current_user }) }

    let_it_be(:group) { create(:group, name: 'public-group') }
    let_it_be(:private_group) { create(:group, name: 'private-group') }
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:other_project) { create(:project, :public) }
    let_it_be(:group_project) { create(:project, :public, group: group) }
    let_it_be(:private_project) { create(:project, :private) }
    let_it_be(:other_private_project) { create(:project, :private) }
    let_it_be(:private_group_project) { create(:project, :private, group: private_group) }

    let_it_be(:user) { create(:user) }

    let(:filters) { {} }

    before_all do
      project.add_developer(user)
      private_project.add_developer(user)
      private_group.add_developer(user)
    end

    before do
      stub_feature_flags(project_finder_similarity_sort: false)
    end

    context 'when user is not logged in' do
      let(:current_user) { nil }

      context 'when no filters are applied' do
        it 'returns all public projects' do
          is_expected.to contain_exactly(project, other_project, group_project)
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

        context 'when searchNamespaces filter is provided' do
          let(:filters) { { search: 'group', search_namespaces: true } }

          it 'returns projects in a matching namespace' do
            is_expected.to contain_exactly(group_project)
          end
        end

        context 'when searchNamespaces filter false' do
          let(:filters) { { search: 'group', search_namespaces: false } }

          it 'returns ignores namespace matches' do
            is_expected.to be_empty
          end
        end
      end
    end

    context 'when user is logged in' do
      let(:current_user) { user }

      context 'when no filters are applied' do
        it 'returns all visible projects for the user' do
          is_expected.to contain_exactly(project, other_project, group_project, private_project, private_group_project)
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
            is_expected.to contain_exactly(project, private_project, private_group_project)
          end
        end

        context 'when searchNamespaces filter is provided' do
          let(:filters) { { search: 'group', search_namespaces: true } }

          it 'returns projects from matching group' do
            is_expected.to contain_exactly(group_project, private_group_project)
          end
        end

        context 'when searchNamespaces filter false' do
          let(:filters) { { search: 'group', search_namespaces: false } }

          it 'returns ignores namespace matches' do
            is_expected.to be_empty
          end
        end

        context 'when ids filter is provided' do
          let(:filters) { { ids: [project.to_global_id.to_s] } }

          it 'returns matching project' do
            is_expected.to contain_exactly(project)
          end
        end

        context 'when sort is similarity' do
          let_it_be(:named_project1) { create(:project, :public, name: 'projAB', path: 'projAB') }
          let_it_be(:named_project2) { create(:project, :public, name: 'projABC', path: 'projABC') }
          let_it_be(:named_project3) { create(:project, :public, name: 'projA', path: 'projA') }

          let(:filters) { { search: 'projA', sort: 'similarity' } }

          it 'returns projects in order of similarity to search' do
            stub_feature_flags(project_finder_similarity_sort: current_user)

            is_expected.to eq([named_project3, named_project1, named_project2])
          end

          it 'returns projects in any order if flag is off' do
            is_expected.to match_array([named_project3, named_project1, named_project2])
          end
        end
      end
    end
  end
end
