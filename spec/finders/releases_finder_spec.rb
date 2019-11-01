# frozen_string_literal: true

require 'spec_helper'

describe ReleasesFinder do
  let(:user)       { create(:user) }
  let(:project)    { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:v1_0_0)     { create(:release, project: project, tag: 'v1.0.0') }
  let(:v1_1_0)     { create(:release, project: project, tag: 'v1.1.0') }
  let(:finder) { described_class.new(project, user) }

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
    end
  end
end
