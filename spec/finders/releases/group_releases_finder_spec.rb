# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Releases::GroupReleasesFinder, feature_category: :groups_and_projects do
  let_it_be(:user)  { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be_with_refind(:project) { create(:project, :small_repo, group: group) }
  let(:params) { {} }
  let(:args) { {} }
  let_it_be_with_reload(:v1_0_0) { create(:release, project: project, tag: 'v1.0.0') }
  let_it_be_with_reload(:v1_1_0) { create(:release, project: project, tag: 'v1.1.0') }
  let_it_be_with_reload(:v1_1_1) { create(:release, project: project, tag: 'v1.1.1') }

  before do
    v1_0_0.update_attribute(:released_at, 2.days.ago)
    v1_1_0.update_attribute(:released_at, 1.day.ago)
    v1_1_1.update_attribute(:released_at, 0.5.days.ago)
  end

  shared_examples_for 'when the user is not part of the project' do
    it 'returns no releases' do
      is_expected.to be_empty
    end
  end

  shared_examples_for 'when the user is not part of the group' do
    before do
      allow(Ability).to receive(:allowed?).with(user, :read_release, group).and_return(false)
    end

    it 'returns no releases' do
      is_expected.to be_empty
    end
  end

  shared_examples_for 'preload' do
    before do
      allow(Ability).to receive(:allowed?).with(user, :read_release, group).and_return(true)
    end

    it 'preloads associations' do
      expect(Release).to receive(:preloaded).once.and_call_original

      releases
    end

    context 'when preload is false' do
      let(:args) { { preload: false } }

      it 'does not preload associations' do
        expect(Release).not_to receive(:preloaded)

        releases
      end
    end
  end

  describe 'when parent is a group' do
    context 'without subgroups' do
      let_it_be_with_refind(:project2) { create(:project, :small_repo, namespace: group) }
      let_it_be_with_reload(:v6) { create(:release, project: project2, tag: 'v6') }

      subject(:releases) { described_class.new(group, user, params).execute(**args) }

      it_behaves_like 'preload'
      it_behaves_like 'when the user is not part of the group'

      context 'when the user is a project guest on one sibling project' do
        before_all do
          project.add_guest(user)
        end

        it 'does not return any releases' do
          expect(releases.size).to eq(0)
          expect(releases).to eq([])
        end
      end

      context 'when the user is a guest on the group' do
        before_all { group.add_guest(user) }

        before do
          v1_0_0.update_attribute(:released_at, 3.days.ago)
          v6.update_attribute(:released_at, 2.days.ago)
          v1_1_0.update_attribute(:released_at, 1.day.ago)
          v1_1_1.update_attribute(:released_at, v1_1_0.released_at)
        end

        it 'sorts by release date and id' do
          expect(releases.size).to eq(4)
          expect(releases).to eq([v1_1_1, v1_1_0, v6, v1_0_0])
        end
      end
    end

    describe 'with subgroups' do
      subject(:releases) { described_class.new(group, user, params).execute(**args) }

      context 'with a single-level subgroup' do
        let_it_be(:subgroup) { create(:group, parent: group) }
        let_it_be_with_refind(:project2) { create(:project, :small_repo, namespace: subgroup) }
        let_it_be_with_reload(:v6) { create(:release, project: project2, tag: 'v6') }

        it_behaves_like 'when the user is not part of the group'

        context 'when the user a project guest in the subgroup project' do
          before_all do
            project2.add_guest(user)
          end

          it 'does not return any releases' do
            expect(releases).to be_empty
          end
        end

        context 'when the user is a guest on the group' do
          before_all { group.add_guest(user) }

          before do
            v6.update_attribute(:released_at, 2.days.ago)
          end

          it 'returns all releases' do
            expect(releases).to match_array([v1_1_1, v1_1_0, v1_0_0, v6])
          end
        end
      end

      context 'with a multi-level subgroup' do
        let_it_be(:subgroup) { create(:group, parent: group) }
        let_it_be(:subsubgroup) { create(:group, parent: subgroup) }
        let_it_be_with_refind(:project2) { create(:project, :small_repo, namespace: subgroup) }
        let_it_be_with_refind(:project3) { create(:project, :small_repo, namespace: subsubgroup) }
        let_it_be_with_reload(:v6) { create(:release, project: project2, tag: 'v6') }
        let_it_be_with_reload(:p3) { create(:release, project: project3, tag: 'p3') }

        before do
          v6.update_attribute(:released_at, 2.days.ago)
          p3.update_attribute(:released_at, 3.days.ago)
        end

        it_behaves_like 'when the user is not part of the group'

        context 'when the user a project guest in the subgroup and subsubgroup project' do
          before_all do
            project2.add_guest(user)
            project3.add_guest(user)
          end

          it 'does not return any releases' do
            expect(releases).to be_empty
          end
        end

        context 'when the user a project guest in the subsubgroup project' do
          before_all do
            project3.add_guest(user)
          end

          it 'does not return any releases' do
            expect(releases).to be_empty
          end
        end

        context 'performance testing' do
          shared_examples 'avoids N+1 queries' do |query_params = {}|
            context 'with subgroups' do
              let(:params) { query_params }

              it 'subgroups avoids N+1 queries' do
                control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
                  releases
                end

                subgroups = create_list(:group, 10, parent: group)
                projects = create_list(:project, 10, namespace: subgroups[0])
                create_list(:release, 10, project: projects[0], author: user)

                expect do
                  releases
                end.not_to exceed_all_query_limit(control)
              end
            end
          end

          it_behaves_like 'avoids N+1 queries'
        end
      end
    end
  end
end
