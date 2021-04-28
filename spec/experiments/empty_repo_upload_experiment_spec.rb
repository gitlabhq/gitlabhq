# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EmptyRepoUploadExperiment, :experiment do
  subject { described_class.new(project: project) }

  let(:project) { create(:project, :repository) }

  describe '#track_initial_write' do
    context 'when experiment is turned on' do
      before do
        stub_experiments(empty_repo_upload: :control)
      end

      it "tracks an event for the first commit on a project" do
        expect(subject).to receive(:commit_count_for).with(project, max_count: described_class::INITIAL_COMMIT_COUNT, experiment: 'empty_repo_upload').and_return(1)

        expect(subject).to receive(:track).with(:initial_write, project: project).and_call_original

        subject.track_initial_write
      end

      it "doesn't track an event for projects with a commit count more than 1" do
        expect(subject).to receive(:commit_count_for).and_return(2)

        expect(subject).not_to receive(:track)

        subject.track_initial_write
      end

      it "doesn't track if the project is older" do
        expect(project).to receive(:created_at).and_return(described_class::TRACKING_START_DATE - 1.minute)

        expect(subject).not_to receive(:track)

        subject.track_initial_write
      end
    end

    context 'when experiment is turned off' do
      it "doesn't track when we generally shouldn't" do
        expect(subject).not_to receive(:track)

        subject.track_initial_write
      end
    end
  end
end
