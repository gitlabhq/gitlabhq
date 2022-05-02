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

  shared_examples_for 'when the user is not part of the group' do
    before do
      allow(Ability).to receive(:allowed?).with(user, :read_release, group).and_return(false)
    end

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

    context 'when the user is a project guest' do
      before do
        project.add_guest(user)
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
      it_behaves_like 'when a tag parameter is passed'
    end
  end
end
