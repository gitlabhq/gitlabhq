require 'spec_helper'

describe ProjectsFinder do
  describe '#execute' do
    let(:user) { create(:user) }
    let(:group) { create(:group, :public) }

    let!(:private_project) do
      create(:project, :private, name: 'A', path: 'A')
    end

    let!(:internal_project) do
      create(:project, :internal, group: group, name: 'B', path: 'B')
    end

    let!(:public_project) do
      create(:project, :public, group: group, name: 'C', path: 'C')
    end

    let!(:shared_project) do
      create(:project, :private, name: 'D', path: 'D')
    end

    let(:params) { {} }
    let(:current_user) { user }
    let(:project_ids_relation) { nil }
    let(:finder) { described_class.new(params: params, current_user: current_user, project_ids_relation: project_ids_relation) }

    subject { finder.execute }

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
          private_project.add_master(user)
        end

        it { is_expected.to match_array([public_project, internal_project, private_project]) }
      end
    end

    describe 'with project_ids_relation' do
      let(:project_ids_relation) { Project.where(id: internal_project.id) }

      it { is_expected.to eq([internal_project]) }
    end

    describe 'filter by visibility_level' do
      before do
        private_project.add_master(user)
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
    end

    describe 'filter by tags' do
      before do
        public_project.tag_list.add('foo')
        public_project.save!
      end

      let(:params) { { tag: 'foo' } }

      it { is_expected.to eq([public_project]) }
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
      let!(:trending_project) { create(:trending_project, project: public_project)  }
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
      end
    end

    describe 'sorting' do
      let(:params) { { sort: 'name_asc' } }

      it { is_expected.to eq([internal_project, public_project]) }
    end
  end
end
