# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReleasesFinder, feature_category: :release_orchestration do
  let_it_be(:user)  { create(:user) }
  let_it_be(:group) { create :group }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let(:params) { {} }
  let(:args) { {} }
  let(:repository) { project.repository }
  let_it_be(:v1_0_0)     { create(:release, project: project, tag: 'v1.0.0', updated_at: 4.days.ago) }
  let_it_be(:v1_1_0)     { create(:release, project: project, tag: 'v1.1.0') }

  shared_examples_for 'when the user is not authorized' do
    it 'returns no releases' do
      is_expected.to be_empty
    end
  end

  shared_examples_for 'when a tag parameter is passed' do
    let(:params) { { tag: 'v1.0.0' } }

    it 'only returns the release with the matching tag' do
      expect(subject).to eq([v1_0_0])
    end
  end

  shared_examples_for 'when a release is tagless' do
    # There shouldn't be tags in this state, but because some exist in production and cause page loading errors, this
    # test exists. We can test empty string but not the nil value since there is a not null constraint at the database
    # level.
    it 'does not return the tagless release' do
      empty_string_tag = create(:release, project: project, tag: 'v99.0.0')
      empty_string_tag.update_column(:tag, '')

      expect(subject).not_to include(empty_string_tag)
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

    it_behaves_like 'when the user is not authorized'

    context 'when the user has guest privileges or higher' do
      before do
        project.add_guest(user)

        v1_0_0.update!(released_at: 2.days.ago, created_at: 1.day.ago)
        v1_1_0.update!(released_at: 1.day.ago, created_at: 2.days.ago)
      end

      it 'returns the releases' do
        is_expected.to be_present
        expect(subject.size).to eq(2)
        expect(subject).to match_array([v1_1_0, v1_0_0])
      end

      context 'with sorting parameters' do
        it 'sorted by released_at in descending order by default' do
          is_expected.to eq([v1_1_0, v1_0_0])
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
      it_behaves_like 'when a tag parameter is passed'
      it_behaves_like 'when a release is tagless'
    end
  end

  describe 'when parent is an array of projects' do
    let_it_be(:project2) { create(:project, :repository, group: group) }
    let_it_be(:v2_0_0) { create(:release, project: project2, tag: 'v2.0.0') }
    let_it_be(:v2_1_0) { create(:release, project: project2, tag: 'v2.1.0') }

    subject { described_class.new([project, project2], user, params).execute(**args) }

    it_behaves_like 'when the user is not authorized'

    context 'when the user has guest privileges or higher on one project' do
      before do
        project.add_guest(user)
      end

      it 'returns the releases of only the authorized project' do
        is_expected.to be_present
        expect(subject.size).to eq(2)
        expect(subject).to match_array([v1_1_0, v1_0_0])
      end
    end

    context 'when the user has guest privileges or higher on all projects' do
      before do
        project.add_guest(user)
        project2.add_guest(user)

        v1_0_0.update!(released_at: 4.days.ago, created_at: 1.day.ago)
        v1_1_0.update!(released_at: 3.days.ago, created_at: 2.days.ago)
        v2_0_0.update!(released_at: 2.days.ago, created_at: 3.days.ago)
        v2_1_0.update!(released_at: 1.day.ago,  created_at: 4.days.ago)
      end

      it 'returns the releases of all projects' do
        is_expected.to be_present
        expect(subject.size).to eq(4)
        expect(subject).to match_array([v2_1_0, v2_0_0, v1_1_0, v1_0_0])
      end

      it_behaves_like 'preload'
      it_behaves_like 'when a tag parameter is passed'
      it_behaves_like 'when a release is tagless'

      context 'with sorting parameters' do
        it 'sorted by released_at in descending order by default' do
          is_expected.to eq([v2_1_0, v2_0_0, v1_1_0, v1_0_0])
        end

        context 'released_at in ascending order' do
          let(:params) { { sort: 'asc' } }

          it { is_expected.to eq([v1_0_0, v1_1_0, v2_0_0, v2_1_0]) }
        end

        context 'order by created_at in descending order' do
          let(:params) { { order_by: 'created_at' } }

          it { is_expected.to eq([v1_0_0, v1_1_0, v2_0_0, v2_1_0]) }
        end

        context 'order by created_at in ascending order' do
          let(:params) { { order_by: 'created_at', sort: 'asc' } }

          it { is_expected.to eq([v2_1_0, v2_0_0, v1_1_0, v1_0_0]) }
        end
      end

      context 'filtered by updated_at' do
        before do
          v1_0_0.update!(updated_at: 4.days.ago)
        end

        context 'when only updated_before is present' do
          let(:params) { { updated_before: 2.days.ago } }

          it { is_expected.to contain_exactly(v1_0_0) }
        end

        context 'when only updated_after is present' do
          let(:params) { { updated_after: 2.days.ago } }

          it { is_expected.not_to include(v1_0_0) }
        end

        context 'when both updated_before and updated_after are present' do
          let(:params) { { updated_before: 2.days.ago, updated_after: 6.days.ago } }

          it { is_expected.to contain_exactly(v1_0_0) }

          context 'when updated_after > updated_before' do
            let(:params) { { updated_before: 6.days.ago, updated_after: 2.days.ago } }

            it { is_expected.to be_empty }
          end

          context 'when updated_after equals updated_before' do
            let(:params) { { updated_after: v1_0_0.updated_at, updated_before: v1_0_0.updated_at } }

            it 'allows an exact match' do
              expect(subject).to contain_exactly(v1_0_0)
            end
          end

          context 'when arguments are invalid datetimes' do
            let(:params) { { updated_after: 'invalid', updated_before: 'invalid' } }

            it 'does not filter by updated_at' do
              expect(subject).to include(v1_0_0)
            end
          end
        end
      end
    end
  end

  describe 'latest releases' do
    let_it_be(:project2) { create(:project, :repository, group: group) }
    let_it_be(:v2_0_0) { create(:release, project: project2) }
    let_it_be(:v2_1_0) { create(:release, project: project2) }

    let(:params) { { latest: true } }

    subject { described_class.new([project, project2], user, params).execute(**args) }

    before do
      v1_0_0.update!(released_at: 4.days.ago, created_at: 1.day.ago)
      v1_1_0.update!(released_at: 3.days.ago, created_at: 2.days.ago)
      v2_0_0.update!(released_at: 2.days.ago, created_at: 3.days.ago)
      v2_1_0.update!(released_at: 1.day.ago,  created_at: 4.days.ago)
    end

    it_behaves_like 'when the user is not authorized'

    context 'when the user has guest privileges or higher on one project' do
      before do
        project.add_guest(user)
      end

      it 'returns the latest release of only the authorized project' do
        is_expected.to eq([v1_1_0])
      end
    end

    context 'when the user has guest privileges or higher on all projects' do
      before do
        project.add_guest(user)
        project2.add_guest(user)
      end

      it 'returns the latest release by released date for each project' do
        is_expected.to match_array([v1_1_0, v2_1_0])
      end

      context 'with order_by_for_latest: created' do
        let(:params) { { latest: true, order_by_for_latest: 'created_at' } }

        it 'returns the latest release by created date for each project' do
          is_expected.to match_array([v1_0_0, v2_0_0])
        end
      end

      context 'when one project does not have releases' do
        it 'returns the latest release of only the project with releases' do
          project.releases.delete_all(:delete_all)

          is_expected.to eq([v2_1_0])
        end
      end

      context 'when all projects do not have releases' do
        it 'returns empty response' do
          project.releases.delete_all(:delete_all)
          project2.releases.delete_all(:delete_all)

          is_expected.to be_empty
        end
      end

      it_behaves_like 'preload'
      it_behaves_like 'when a release is tagless'
    end
  end
end
