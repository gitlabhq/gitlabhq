require 'spec_helper'

describe GithubService::StatusMessage do
  include Rails.application.routes.url_helpers

  let(:project) { double(:project, namespace: "me", to_s: 'example_project') }

  describe '#description' do
    it 'includes human readable gitlab status' do
      subject = described_class.new(project, detailed_status: 'passed')

      expect(subject.description).to eq "Pipeline passed on GitLab"
    end

    it 'gets truncated to 140 chars' do
      dummy_text = 'a' * 500
      subject = described_class.new(project, detailed_status: dummy_text)

      expect(subject.description.length).to eq 140
    end
  end

  describe '#status' do
    using RSpec::Parameterized::TableSyntax

    where(:gitlab_status, :github_status) do
      'pending'  | :pending
      'created'  | :pending
      'running'  | :pending
      'manual'   | :pending
      'success'  | :success
      'skipped'  | :success
      'failed'   | :failure
      'canceled' | :error
    end

    with_them do
      it 'transforms status' do
        subject = described_class.new(project, status: gitlab_status)

        expect(subject.status).to eq github_status
      end
    end
  end

  describe '#status_options' do
    let(:subject) { described_class.new(project, id: 1) }

    it 'includes context' do
      expect(subject.status_options[:context]).to be_a String
    end

    it 'includes target_url' do
      expect(subject.status_options[:target_url]).to be_a String
    end

    it 'includes description' do
      expect(subject.status_options[:description]).to be_a String
    end
  end

  describe '.from_pipeline_data' do
    let(:pipeline) { create(:ci_pipeline) }
    let(:project) { pipeline.project }
    let(:sample_data) { Gitlab::DataBuilder::Pipeline.build(pipeline) }
    let(:subject) { described_class.from_pipeline_data(project, sample_data) }

    it 'builds an instance of GithubService::StatusMessage' do
      expect(subject).to be_a described_class
    end

    describe 'builds an object with' do
      specify 'sha' do
        expect(subject.sha).to eq pipeline.sha
      end

      specify 'status' do
        expect(subject.status).to eq :pending
      end

      specify 'target_url' do
        expect(subject.target_url).to end_with pipeline_path(pipeline)
      end

      specify 'description' do
        expect(subject.description).to eq "Pipeline pending on GitLab"
      end

      specify 'context' do
        expect(subject.context).to eq "ci/gitlab/#{pipeline.ref}"
      end

      context 'blocked pipeline' do
        let(:pipeline) { create(:ci_pipeline, :blocked) }

        it 'uses human readable status which can be used in a sentence' do
          expect(subject.description). to eq 'Pipeline waiting for manual action on GitLab'
        end
      end
    end
  end
end
