# frozen_string_literal: true

require 'spec_helper'

describe ReleasesFinder do
  let(:user)       { create(:user) }
  let(:project)    { create(:project, :repository) }
  let(:params)     { {} }
  let(:repository) { project.repository }
  let(:v1_0_0)     { create(:release, project: project, tag: 'v1.0.0') }
  let(:v1_1_0)     { create(:release, project: project, tag: 'v1.1.0') }
  let(:finder) { described_class.new(project, user, params) }

  before do
    v1_0_0.update_attribute(:released_at, 2.days.ago)
    v1_1_0.update_attribute(:released_at, 1.day.ago)
  end

  describe '#execute' do
    subject { finder.execute(**args) }

    let(:args) { {} }

    context 'when the user is not part of the project' do
      it 'returns no releases' do
        is_expected.to be_empty
      end
    end

    context 'when the user is a project developer' do
      before do
        project.add_developer(user)
      end

      it 'sorts by release date' do
        is_expected.to be_present
        expect(subject.size).to eq(2)
        expect(subject).to eq([v1_1_0, v1_0_0])
      end

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

      # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/27716
      context 'when tag is nil' do
        before do
          v1_0_0.update_column(:tag, nil)
        end

        it 'ignores rows with a nil tag' do
          expect(subject.size).to eq(1)
          expect(subject).to eq([v1_1_0])
        end
      end

      context 'when a tag parameter is passed' do
        let(:params) { { tag: 'v1.0.0' } }

        it 'only returns the release with the matching tag' do
          expect(subject).to eq([v1_0_0])
        end
      end
    end
  end
end
