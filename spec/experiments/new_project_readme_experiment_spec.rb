# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NewProjectReadmeExperiment, :experiment do
  subject { described_class.new(actor: actor) }

  let(:actor) { User.new(id: 42, created_at: Time.current) }

  describe "exclusions" do
    let(:threshold) { described_class::MAX_ACCOUNT_AGE }

    it { is_expected.to exclude(actor: User.new(created_at: (threshold + 1.minute).ago)) }
    it { is_expected.not_to exclude(actor: User.new(created_at: (threshold - 1.minute).ago)) }
  end

  describe "the control behavior" do
    subject { described_class.new(actor: actor).run(:control) }

    it { is_expected.to be false }
  end

  describe "the candidate behavior" do
    subject { described_class.new(actor: actor).run(:candidate) }

    it { is_expected.to be true }
  end

  context "when tracking initial writes" do
    let!(:project) { create(:project, :repository) }

    def stub_gitaly_count(count = 1)
      allow(Gitlab::GitalyClient).to receive(:call).and_call_original
      allow(Gitlab::GitalyClient).to receive(:call).with(anything, :commit_service, :count_commits, anything, anything)
        .and_return(double(count: count))
    end

    before do
      stub_gitaly_count
    end

    it "tracks an event for the first commit on a project with a repository" do
      expect(subject).to receive(:track).with(:write, property: project.created_at.to_s, value: 1).and_call_original

      subject.track_initial_writes(project)
    end

    it "tracks an event for the second commit on a project with a repository" do
      stub_gitaly_count(2)

      expect(subject).to receive(:track).with(:write, property: project.created_at.to_s, value: 2).and_call_original

      subject.track_initial_writes(project)
    end

    it "doesn't track if the repository has more then 2 commits" do
      stub_gitaly_count(3)

      expect(subject).not_to receive(:track)

      subject.track_initial_writes(project)
    end

    it "doesn't track when we generally shouldn't" do
      allow(subject).to receive(:should_track?).and_return(false)

      expect(subject).not_to receive(:track)

      subject.track_initial_writes(project)
    end

    it "doesn't track if the project is older" do
      expect(project).to receive(:created_at).and_return(described_class::EXPERIMENT_START_DATE - 1.minute)

      expect(subject).not_to receive(:track)

      subject.track_initial_writes(project)
    end

    it "handles exceptions by logging them" do
      allow(Gitlab::GitalyClient).to receive(:call).with(anything, :commit_service, :count_commits, anything, anything)
        .and_raise(e = StandardError.new('_message_'))

      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(e, experiment: 'new_project_readme')

      subject.track_initial_writes(project)
    end
  end
end
