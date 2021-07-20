# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectsFinder do
  include AdminModeHelper

  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group, :public) }

    let_it_be(:private_project) do
      create(:project, :private, name: 'A', path: 'A')
    end

    let_it_be(:internal_project) do
      create(:project, :internal, group: group, name: 'B', path: 'B')
    end

    let_it_be(:public_project) do
      create(:project, :public, group: group, name: 'C', path: 'C')
    end

    let_it_be(:shared_project) do
      create(:project, :private, name: 'D', path: 'D')
    end

    let(:params) { {} }
    let(:current_user) { user }
    let(:project_ids_relation) { nil }
    let(:use_cte) { true }
    let(:finder) { described_class.new(params: params.merge(use_cte: use_cte), current_user: current_user, project_ids_relation: project_ids_relation) }

    subject { finder.execute }

    shared_examples 'ProjectFinder#execute examples' do
      describe 'without a user' do
        let(:current_user) { nil }

        it { is_expected.to eq([public_project]) }
      end

      describe 'with a user' do
        describe 'without private projects' do
          it { is_expected.to match_array([public_project, internal_project]) }
        end

        describe 'with private projects' do
          before do
            private_project.add_maintainer(user)
          end

          it { is_expected.to match_array([public_project, internal_project, private_project]) }
        end
      end

      describe 'with project_ids_relation' do
        let(:project_ids_relation) { Project.where(id: internal_project.id) }

        it { is_expected.to eq([internal_project]) }
      end

      describe 'with id_after' do
        context 'only returns projects with a project id greater than given' do
          let(:params) { { id_after: internal_project.id }}

          it { is_expected.to eq([public_project]) }
        end
      end

      describe 'with id_before' do
        context 'only returns projects with a project id less than given' do
          let(:params) { { id_before: public_project.id }}

          it { is_expected.to eq([internal_project]) }
        end
      end

      describe 'with both id_before and id_after' do
        context 'only returns projects with a project id less than given' do
          let!(:projects) { create_list(:project, 5, :public) }
          let(:params) { { id_after: projects.first.id, id_before: projects.last.id }}

          it { is_expected.to contain_exactly(*projects[1..-2]) }
        end
      end

      describe 'regression: Combination of id_before/id_after and joins requires fully qualified column names' do
        context 'only returns projects with a project id less than given and matching search' do
          subject { finder.execute.joins(:route) }

          let(:params) { { id_before: public_project.id }}

          it { is_expected.to eq([internal_project]) }
        end

        context 'only returns projects with a project id greater than given and matching search' do
          subject { finder.execute.joins(:route) }

          let(:params) { { id_after: internal_project.id }}

          it { is_expected.to eq([public_project]) }
        end
      end

      describe 'filter by visibility_level' do
        before do
          private_project.add_maintainer(user)
        end

        context 'private' do
          let(:params) { { visibility_level: Gitlab::VisibilityLevel::PRIVATE } }

          it { is_expected.to eq([private_project]) }
        end

        context 'internal' do
          let(:params) { { visibility_level: Gitlab::VisibilityLevel::INTERNAL } }

          it { is_expected.to eq([internal_project]) }
        end

        context 'public' do
          let(:params) { { visibility_level: Gitlab::VisibilityLevel::PUBLIC } }

          it { is_expected.to eq([public_project]) }
        end

        context 'as string' do
          let(:params) { { visibility_level: Gitlab::VisibilityLevel::INTERNAL.to_s } }

          it { is_expected.to eq([internal_project]) }
        end
      end

      describe 'filter by tags (deprecated)' do
        before do
          public_project.topic_list = 'foo'
          public_project.save!
        end

        let(:params) { { tag: 'foo' } }

        it { is_expected.to eq([public_project]) }
      end

      describe 'filter by topics' do
        before do
          public_project.topic_list = 'foo, bar'
          public_project.save!
        end

        context 'single topic' do
          let(:params) { { topic: 'foo' } }

          it { is_expected.to eq([public_project]) }
        end

        context 'multiple topics' do
          let(:params) { { topic: 'bar, foo' } }

          it { is_expected.to eq([public_project]) }
        end

        context 'one topic matches, other one does not' do
          let(:params) { { topic: 'foo, xyz' } }

          it { is_expected.to eq([]) }
        end

        context 'no matching topic' do
          let(:params) { { topic: 'xyz' } }

          it { is_expected.to eq([]) }
        end
      end

      describe 'filter by personal' do
        let!(:personal_project) { create(:project, namespace: user.namespace) }
        let(:params) { { personal: true } }

        it { is_expected.to eq([personal_project]) }
      end

      describe 'filter by search' do
        let(:params) { { search: 'C' } }

        it { is_expected.to eq([public_project]) }
      end

      describe 'filter by name for backward compatibility' do
        let(:params) { { name: 'C' } }

        it { is_expected.to eq([public_project]) }
      end

      describe 'filter by search with minimum search length' do
        context 'when search term is shorter than minimum length' do
          let(:params) { { search: 'C', minimum_search_length: 3 } }

          it { is_expected.to be_empty }
        end

        context 'when search term is longer than minimum length' do
          let(:project) { create(:project, :public, group: group, name: 'test_project') }
          let(:params) { { search: 'test', minimum_search_length: 3 } }

          it { is_expected.to eq([project]) }
        end

        context 'when minimum length is invalid' do
          let(:params) { { search: 'C', minimum_search_length: 'x' } }

          it 'ignores the minimum length param' do
            is_expected.to eq([public_project])
          end
        end
      end

      describe 'filter by group name' do
        let(:params) { { name: group.name, search_namespaces: true } }

        it { is_expected.to eq([public_project, internal_project]) }
      end

      describe 'filter by archived' do
        let!(:archived_project) { create(:project, :public, :archived, name: 'E', path: 'E') }

        context 'non_archived=true' do
          let(:params) { { non_archived: true } }

          it { is_expected.to match_array([public_project, internal_project]) }
        end

        context 'non_archived=false' do
          let(:params) { { non_archived: false } }

          it { is_expected.to match_array([public_project, internal_project, archived_project]) }
        end

        describe 'filter by archived only' do
          let(:params) { { archived: 'only' } }

          it { is_expected.to eq([archived_project]) }
        end

        describe 'filter by archived for backward compatibility' do
          let(:params) { { archived: false } }

          it { is_expected.to match_array([public_project, internal_project]) }
        end
      end

      describe 'filter by trending' do
        let!(:trending_project) { create(:trending_project, project: public_project) }
        let(:params) { { trending: true } }

        it { is_expected.to eq([public_project]) }
      end

      describe 'filter by owned' do
        let(:params) { { owned: true } }
        let!(:owned_project) { create(:project, :private, namespace: current_user.namespace) }

        it { is_expected.to eq([owned_project]) }
      end

      describe 'filter by non_public' do
        let(:params) { { non_public: true } }

        before do
          private_project.add_developer(current_user)
        end

        it { is_expected.to eq([private_project]) }
      end

      describe 'filter by starred' do
        let(:params) { { starred: true } }

        before do
          current_user.toggle_star(public_project)
        end

        it { is_expected.to eq([public_project]) }

        it 'returns only projects the user has access to' do
          current_user.toggle_star(private_project)

          is_expected.to eq([public_project])
          expect(subject.count).to eq(1)
          expect(subject.limit(1000).count).to eq(1)
        end
      end

      describe 'filter by without_deleted' do
        let_it_be(:pending_delete_project) { create(:project, :public, pending_delete: true) }

        let(:params) { { without_deleted: without_deleted } }

        shared_examples 'returns all projects' do
          it { expect(subject).to include(public_project, internal_project, pending_delete_project) }
        end

        context 'when without_deleted is true' do
          let(:without_deleted) { true }

          it 'returns projects that are not pending_delete' do
            expect(subject).not_to include(pending_delete_project)
            expect(subject).to include(public_project, internal_project)
          end
        end

        context 'when without_deleted is false' do
          let(:without_deleted) { false }

          it_behaves_like 'returns all projects'
        end

        context 'when without_deleted is nil' do
          let(:without_deleted) { nil }

          it_behaves_like 'returns all projects'
        end

        context 'when without_deleted is not present' do
          let(:params) { {} }

          it_behaves_like 'returns all projects'
        end
      end

      describe 'filter by last_activity_after' do
        let(:params) { { last_activity_after: 60.minutes.ago } }

        before do
          internal_project.update!(last_activity_at: Time.now)
          public_project.update!(last_activity_at: 61.minutes.ago)
        end

        it { is_expected.to match_array([internal_project]) }
      end

      describe 'filter by last_activity_before' do
        let(:params) { { last_activity_before: 60.minutes.ago } }

        before do
          internal_project.update!(last_activity_at: Time.now)
          public_project.update!(last_activity_at: 61.minutes.ago)
        end

        it { is_expected.to match_array([public_project]) }
      end

      describe 'filter by repository_storage' do
        let(:params) { { repository_storage: 'nfs-05' } }
        let!(:project) { create(:project, :public) }

        before do
          project.update_columns(repository_storage: 'nfs-05')
        end

        it { is_expected.to match_array([project]) }
      end

      describe 'sorting' do
        let_it_be(:more_projects) do
          [
            create(:project, :internal, group: group, name: 'projA', path: 'projA'),
            create(:project, :internal, group: group, name: 'projABC', path: 'projABC'),
            create(:project, :internal, group: group, name: 'projAB', path: 'projAB')
          ]
        end

        context 'when sorting by a field' do
          let(:params) { { sort: 'name_asc' } }

          it { is_expected.to eq(([internal_project, public_project] + more_projects).sort_by { |p| p[:name] }) }
        end

        context 'when sorting by similarity' do
          let(:params) { { sort: 'similarity', search: 'pro' } }

          it { is_expected.to eq([more_projects[0], more_projects[2], more_projects[1]]) }
        end

        context 'when no sort is provided' do
          it { is_expected.to eq(([internal_project, public_project] + more_projects).sort_by { |p| p[:id] }.reverse) }
        end
      end

      describe 'with admin user' do
        let(:user) { create(:admin) }

        context 'admin mode enabled' do
          before do
            enable_admin_mode!(current_user)
          end

          it { is_expected.to match_array([public_project, internal_project, private_project, shared_project]) }
        end

        context 'admin mode disabled' do
          it { is_expected.to match_array([public_project, internal_project]) }
        end
      end
    end

    describe 'without CTE flag enabled' do
      let(:use_cte) { false }

      it_behaves_like 'ProjectFinder#execute examples'
    end

    describe 'with CTE flag enabled' do
      let(:use_cte) { true }

      it_behaves_like 'ProjectFinder#execute examples'
    end
  end
end
