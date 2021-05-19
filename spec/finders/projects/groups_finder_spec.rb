# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GroupsFinder do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:root_group) { create(:group, :public) }
    let_it_be(:project_group) { create(:group, :public, parent: root_group) }
    let_it_be(:shared_group_with_dev_access) { create(:group, :private, parent: root_group) }
    let_it_be(:shared_group_with_reporter_access) { create(:group, :public) }

    let_it_be(:public_project) { create(:project, :public, group: project_group) }
    let_it_be(:private_project) { create(:project, :private, group: project_group) }

    before_all do
      [public_project, private_project].each do |project|
        create(:project_group_link, :developer, group: shared_group_with_dev_access, project: project)
        create(:project_group_link, :reporter, group: shared_group_with_reporter_access, project: project)
      end
    end

    let(:params) { {} }
    let(:current_user) { user }
    let(:finder) { described_class.new(project: project, current_user: current_user, params: params) }

    subject { finder.execute }

    shared_examples 'finding related groups' do
      it 'returns ancestor groups for this project' do
        is_expected.to match_array([project_group, root_group])
      end

      context 'when the project does not belong to any group' do
        before do
          allow(project).to receive(:group) { nil }
        end

        it { is_expected.to eq([]) }
      end

      context 'when shared groups option is on' do
        let(:params) { { with_shared: true } }

        it 'returns ancestor and all shared groups' do
          is_expected.to match_array([project_group, root_group, shared_group_with_dev_access, shared_group_with_reporter_access])
        end

        context 'when shared_min_access_level is developer' do
          let(:params) { super().merge(shared_min_access_level: Gitlab::Access::DEVELOPER) }

          it 'returns ancestor and shared groups with at least developer access' do
            is_expected.to match_array([project_group, root_group, shared_group_with_dev_access])
          end
        end

        context 'when shared_visible_only is on' do
          let(:params) { super().merge(shared_visible_only: true) }

          it 'returns ancestor and public shared groups' do
            is_expected.to match_array([project_group, root_group, shared_group_with_reporter_access])
          end

          context 'when user has access to the private shared group' do
            before do
              shared_group_with_dev_access.add_guest(current_user)
            end

            it 'returns ancestor and shared groups user has access to' do
              is_expected.to match_array([project_group, root_group, shared_group_with_reporter_access, shared_group_with_dev_access])
            end
          end
        end
      end

      context 'when skip group option is on' do
        let(:params) { { skip_groups: [project_group.id] } }

        it 'excludes provided groups' do
          is_expected.to match_array([root_group])
        end
      end
    end

    context 'Public project' do
      it_behaves_like 'finding related groups' do
        let(:project) { public_project }

        context 'when user is not authorized' do
          let(:current_user) { nil }

          it 'returns ancestor groups for this project' do
            is_expected.to match_array([project_group, root_group])
          end

          context 'when visible shared groups are requested' do
            let(:params) do
              {
                with_shared: true,
                shared_visible_only: true
              }
            end

            it 'returns ancestor groups and public shared groups for this project' do
              is_expected.to match_array([project_group, root_group, shared_group_with_reporter_access])
            end
          end
        end
      end
    end

    context 'Private project' do
      it_behaves_like 'finding related groups' do
        let(:project) { private_project }

        before do
          project.add_developer(user)
        end

        context 'when user is not authorized' do
          let(:current_user) { nil }

          it { is_expected.to eq([]) }
        end
      end
    end

    context 'Missing project' do
      let(:project) { nil }

      it { is_expected.to eq([]) }
    end
  end
end
