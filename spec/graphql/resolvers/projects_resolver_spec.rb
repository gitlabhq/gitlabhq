# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ProjectsResolver, feature_category: :source_code_management do
  include GraphqlHelpers

  describe '#resolve' do
    subject { resolve(described_class, obj: nil, args: filters, ctx: { current_user: current_user }).items }

    let_it_be(:user) { create(:user, :with_namespace) }
    let_it_be(:group) { create(:group, name: 'public-group') }
    let_it_be(:private_group) { create(:group, name: 'private-group', developers: user) }
    let_it_be(:project) { create(:project, :public, topic_list: %w[ruby javascript], developers: user) }
    let_it_be(:other_project) { create(:project, :public) }
    let_it_be(:group_project) { create(:project, :public, group: group) }
    let_it_be(:private_project) { create(:project, :private, developers: user) }
    let_it_be(:other_private_project) { create(:project, :private) }
    let_it_be(:private_group_project) { create(:project, :private, group: private_group) }
    let_it_be(:private_personal_project) { create(:project, :private, namespace: user.namespace) }
    let_it_be(:other_org) { create(:organization, :private) }
    let_it_be(:other_org_project) { create(:project, organization: other_org, topic_list: ['postgres']) }
    let_it_be(:marked_for_deletion_on) { Date.yesterday }
    let_it_be(:project_marked_for_deletion) do
      create(:project, marked_for_deletion_at: marked_for_deletion_on, developers: user)
    end

    let(:filters) { {} }

    before do
      ::Current.organization = organization
    end

    context 'when user is not logged in' do
      let(:current_user) { nil }
      let(:organization) { project.organization }

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

        context 'when topics filter is provided' do
          let(:filters) { { topics: %w[ruby] } }

          it 'returns matching project' do
            is_expected.to contain_exactly(project)
          end
        end

        context 'when filtering topics from another organization' do
          let(:filters) { { topics: %w[postgres] } }

          it 'returns no matching project' do
            is_expected.to be_empty
          end
        end

        context 'when personal filter is provided' do
          let(:filters) { { personal: true } }

          it 'returns all public projects' do
            is_expected.to contain_exactly(project, other_project, group_project)
          end
        end
      end
    end

    context 'when user is logged in' do
      let(:current_user) { user }
      let(:organization) { user.organizations.first }
      let(:visible_projects) do
        [project, other_project, group_project, private_project, private_group_project, private_personal_project,
          project_marked_for_deletion]
      end

      context 'when no filters are applied' do
        it 'returns all visible projects for the user' do
          is_expected.to match_array(visible_projects)
        end

        context 'when aimedForDeletion filter is true' do
          let(:filters) { { aimed_for_deletion: true } }

          it { is_expected.to contain_exactly(project_marked_for_deletion) }
        end

        context 'with markedForDeletion filters', :freeze_time do
          context 'when a project has been marked for deletion on the given date' do
            let(:filters) { { marked_for_deletion_on: marked_for_deletion_on } }

            it { is_expected.to contain_exactly(project_marked_for_deletion) }
          end

          context 'when no projects have been marked for deletion on the given date' do
            let(:filters) { { marked_for_deletion_on: (marked_for_deletion_on - 2.days) } }

            it { is_expected.to be_empty }
          end
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
            is_expected.to contain_exactly(
              project, private_project, private_group_project, private_personal_project, project_marked_for_deletion
            )
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

        context 'when sorting' do
          let_it_be(:named_project1) { create(:project, :public, name: 'projAB', path: 'projAB') }
          let_it_be(:named_project2) { create(:project, :public, name: 'projABC', path: 'projABC') }
          let_it_be(:named_project3) { create(:project, :public, name: 'projA', path: 'projA') }
          let_it_be(:named_projects) { [named_project1, named_project2, named_project3] }

          context 'when sorting by similarity' do
            let(:filters) { { search: 'projA', sort: 'similarity' } }

            it 'returns projects in order of similarity to search' do
              is_expected.to eq([named_project3, named_project1, named_project2])
            end
          end

          context 'when no sort is provided' do
            it 'returns projects in descending order by id' do
              is_expected.to match_array((visible_projects + named_projects).sort_by { |p| p[:id] }.reverse)
            end
          end
        end

        context 'when topics filter is provided' do
          let(:filters) { { topics: %w[ruby] } }

          it 'returns matching project' do
            is_expected.to contain_exactly(project)
          end
        end

        context 'when filtering topics from another organization' do
          let(:filters) { { topics: %w[postgres] } }

          it 'returns no matching project' do
            is_expected.to be_empty
          end
        end

        context 'when personal filter is provided' do
          let(:filters) { { personal: true } }

          it 'returns matching project' do
            is_expected.to contain_exactly(private_personal_project)
          end
        end
      end
    end
  end
end
