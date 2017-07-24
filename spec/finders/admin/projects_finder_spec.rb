require 'spec_helper'

describe Admin::ProjectsFinder do
  describe '#execute' do
    let(:user) { create(:user) }
    let(:group) { create(:group, :public) }

    let!(:private_project) do
      create(:empty_project, :private, name: 'A', path: 'A')
    end

    let!(:internal_project) do
      create(:empty_project, :internal, group: group, name: 'B', path: 'B')
    end

    let!(:public_project) do
      create(:empty_project, :public, group: group, name: 'C', path: 'C')
    end

    let!(:shared_project) do
      create(:empty_project, :private, name: 'D', path: 'D')
    end

    let(:params) { {} }
    let(:current_user) { user }
    let(:project_ids_relation) { nil }
    let(:finder) { described_class.new(params: params, current_user: current_user) }

    subject { finder.execute.to_a }

    context 'without a user' do
      let(:current_user) { nil }

      it { is_expected.to match_array([shared_project, public_project, internal_project, private_project]) }
    end

    context 'with a user' do
      it { is_expected.to match_array([shared_project, public_project, internal_project, private_project]) }
    end

    context 'filter by namespace_id' do
      let(:namespace) { create(:namespace) }
      let!(:project_in_namespace) { create(:empty_project, namespace: namespace) }
      let(:params) { { namespace_id: namespace.id } }

      it { is_expected.to eq([project_in_namespace]) }
    end

    context 'filter by visibility_level' do
      before do
        private_project.add_master(user)
      end

      context 'private' do
        let(:params) { { visibility_level: Gitlab::VisibilityLevel::PRIVATE } }

        it { is_expected.to match_array([shared_project, private_project]) }
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

    context 'filter by push' do
      let(:pushed_event) { create(:event, :pushed) }
      let!(:project_with_push) { pushed_event.project }
      let(:params) { { with_push: true } }

      it { is_expected.to eq([project_with_push]) }
    end

    context 'filter by abandoned' do
      before do
        private_project.update(last_activity_at: Time.zone.now - 6.months - 1.minute)
      end

      let(:params) { { abandoned: true } }

      it { is_expected.to eq([private_project]) }
    end

    context 'filter by last_repository_check_failed' do
      before do
        private_project.update(last_repository_check_failed: true)
      end

      let(:params) { { last_repository_check_failed: true } }

      it { is_expected.to eq([private_project]) }
    end

    context 'filter by archived' do
      let!(:archived_project) { create(:empty_project, :public, :archived, name: 'E', path: 'E') }

      context 'archived=false' do
        let(:params) { { archived: false } }

        it { is_expected.to match_array([shared_project, public_project, internal_project, private_project]) }
      end

      context 'archived=true' do
        let(:params) { { archived: true } }

        it { is_expected.to match_array([archived_project, shared_project, public_project, internal_project, private_project]) }
      end
    end

    context 'filter by personal' do
      let!(:personal_project) { create(:empty_project, namespace: user.namespace) }
      let(:params) { { personal: true } }

      it { is_expected.to eq([personal_project]) }
    end

    context 'filter by name' do
      let(:params) { { name: 'C' } }

      it { is_expected.to match_array([shared_project, public_project, private_project]) }
    end

    context 'sorting' do
      let(:params) { { sort: 'name_asc' } }

      it { is_expected.to eq([private_project, internal_project, public_project, shared_project]) }
    end
  end
end
