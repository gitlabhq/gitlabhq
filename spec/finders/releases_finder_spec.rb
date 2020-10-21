# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReleasesFinder do
  let(:user)  { create(:user) }
  let(:group) { create :group }
  let(:project) { create(:project, :repository, group: group) }
  let(:params) { {} }
  let(:args) { {} }
  let(:repository) { project.repository }
  let(:v1_0_0)     { create(:release, project: project, tag: 'v1.0.0') }
  let(:v1_1_0)     { create(:release, project: project, tag: 'v1.1.0') }

  before do
    v1_0_0.update_attribute(:released_at, 2.days.ago)
    v1_1_0.update_attribute(:released_at, 1.day.ago)
  end

  shared_examples_for 'when the user is not part of the project' do
    it 'returns no releases' do
      is_expected.to be_empty
    end
  end

  # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/27716
  shared_examples_for 'when tag is nil' do
    before do
      v1_0_0.update_column(:tag, nil)
    end

    it 'ignores rows with a nil tag' do
      expect(subject.size).to eq(1)
      expect(subject).to eq([v1_1_0])
    end
  end

  shared_examples_for 'when a tag parameter is passed' do
    let(:params) { { tag: 'v1.0.0' } }

    it 'only returns the release with the matching tag' do
      expect(subject).to eq([v1_0_0])
    end
  end

  shared_examples_for 'preload' do
    it 'preloads associations' do
      expect(Release).to receive(:preloaded).once.and_call_original

      subject
    end

    context 'when preload is false' do
      let(:args) { { preload: false } }

      it 'does not preload associations' do
        expect(Release).not_to receive(:preloaded)

        subject
      end
    end
  end

  describe 'when parent is a project' do
    subject { described_class.new(project, user, params).execute(**args) }

    it_behaves_like 'when the user is not part of the project'

    context 'when the user is a project developer' do
      before do
        project.add_developer(user)
      end

      it 'sorts by release date' do
        is_expected.to be_present
        expect(subject.size).to eq(2)
        expect(subject).to eq([v1_1_0, v1_0_0])
      end

      context 'with sorting parameters' do
        before do
          v1_1_0.update_attribute(:created_at, 3.days.ago)
        end

        context 'by default is released_at in descending order' do
          it { is_expected.to eq([v1_1_0, v1_0_0]) }
        end

        context 'released_at in ascending order' do
          let(:params) { { sort: 'asc' } }

          it { is_expected.to eq([v1_0_0, v1_1_0]) }
        end

        context 'order by created_at in descending order' do
          let(:params) { { order_by: 'created_at' } }

          it { is_expected.to eq([v1_0_0, v1_1_0]) }
        end

        context 'order by created_at in ascending order' do
          let(:params) { { order_by: 'created_at', sort: 'asc' } }

          it { is_expected.to eq([v1_1_0, v1_0_0]) }
        end
      end

      it_behaves_like 'preload'
      it_behaves_like 'when tag is nil'
      it_behaves_like 'when a tag parameter is passed'
    end
  end

  describe 'when parent is a group' do
    context 'without subgroups' do
      let(:project2)    { create(:project, :repository, namespace: group) }
      let!(:v6)         { create(:release, project: project2, tag: 'v6') }

      subject { described_class.new(group, user, params).execute(**args) }

      it_behaves_like 'when the user is not part of the project'

      context 'when the user is a project developer on one sibling project' do
        before do
          project.add_developer(user)
          v1_0_0.update_attribute(:released_at, 3.days.ago)
          v1_1_0.update_attribute(:released_at, 1.day.ago)
        end

        it 'sorts by release date' do
          expect(subject.size).to eq(2)
          expect(subject).to eq([v1_1_0, v1_0_0])
        end
      end

      context 'when the user is a project developer on all projects' do
        before do
          project.add_developer(user)
          project2.add_developer(user)
          v1_0_0.update_attribute(:released_at, 3.days.ago)
          v6.update_attribute(:released_at, 2.days.ago)
          v1_1_0.update_attribute(:released_at, 1.day.ago)
        end

        it 'sorts by release date' do
          expect(subject.size).to eq(3)
          expect(subject).to eq([v1_1_0, v6, v1_0_0])
        end

        it_behaves_like 'when a tag parameter is passed'
      end
    end

    describe 'with subgroups' do
      let(:params) { { include_subgroups: true } }

      subject { described_class.new(group, user, params).execute(**args) }

      context 'with a single-level subgroup' do
        let(:subgroup) { create :group, parent: group }
        let(:project2) { create(:project, :repository, namespace: subgroup) }
        let!(:v6)      { create(:release, project: project2, tag: 'v6') }

        it_behaves_like 'when the user is not part of the project'

        context 'when the user a project developer in the subgroup project' do
          before do
            project2.add_developer(user)
          end

          it 'returns only the subgroup releases' do
            expect(subject).to match_array([v6])
          end
        end

        context 'when the user a project developer in both projects' do
          before do
            project.add_developer(user)
            project2.add_developer(user)
            v6.update_attribute(:released_at, 2.days.ago)
          end

          it 'returns all releases' do
            expect(subject).to match_array([v1_1_0, v1_0_0, v6])
          end

          it_behaves_like 'when a tag parameter is passed'
        end
      end

      context 'with a multi-level subgroup' do
        let(:subgroup) { create :group, parent: group }
        let(:subsubgroup) { create :group, parent: subgroup }
        let(:project2) { create(:project, :repository, namespace: subgroup) }
        let(:project3) { create(:project, :repository, namespace: subsubgroup) }
        let!(:v6)      { create(:release, project: project2, tag: 'v6') }
        let!(:p3)      { create(:release, project: project3, tag: 'p3') }

        before do
          v6.update_attribute(:released_at, 2.days.ago)
          p3.update_attribute(:released_at, 3.days.ago)
        end

        it_behaves_like 'when the user is not part of the project'

        context 'when the user a project developer in the subgroup and subsubgroup project' do
          before do
            project2.add_developer(user)
            project3.add_developer(user)
          end

          it 'returns only the subgroup and subsubgroup releases' do
            expect(subject).to match_array([v6, p3])
          end
        end

        context 'when the user a project developer in the subsubgroup project' do
          before do
            project3.add_developer(user)
          end

          it 'returns only the subsubgroup releases' do
            expect(subject).to match_array([p3])
          end
        end

        context 'when the user a project developer in all projects' do
          before do
            project.add_developer(user)
            project2.add_developer(user)
            project3.add_developer(user)
          end

          it 'returns all releases' do
            expect(subject).to match_array([v1_1_0, v6, v1_0_0, p3])
          end

          it_behaves_like 'when a tag parameter is passed'
        end
      end
    end
  end
end
