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

    before do
      stub_experiments(new_project_readme: :control)
    end

    it "tracks an event for the first commit on a project with a repository" do
      expect(subject).to receive(:commit_count_for).with(project, default_count: described_class::INITIAL_WRITE_LIMIT, max_count: described_class::INITIAL_WRITE_LIMIT, experiment: 'new_project_readme').and_return(1)
      expect(subject).to receive(:track).with(:write, property: project.created_at.to_s, value: 1).and_call_original

      subject.track_initial_writes(project)
    end

    it "tracks an event for the second commit on a project with a repository" do
      allow(subject).to receive(:commit_count_for).and_return(2)

      expect(subject).to receive(:track).with(:write, property: project.created_at.to_s, value: 2).and_call_original

      subject.track_initial_writes(project)
    end

    it "doesn't track if the repository has more then 2 commits" do
      allow(subject).to receive(:commit_count_for).and_return(3)

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
  end
end
