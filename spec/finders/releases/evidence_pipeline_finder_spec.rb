# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Releases::EvidencePipelineFinder, '#execute' do
  let(:params) { {} }
  let(:project) { create(:project, :repository) }
  let(:tag_name) { project.repository.tag_names.first }
  let(:sha) { project.repository.find_tag(tag_name).dereferenced_target.sha }
  let!(:pipeline) { create(:ci_empty_pipeline, sha: sha, project: project) }

  subject { described_class.new(project, params).execute }

  context 'when the tag is passed' do
    let(:params) { { tag: tag_name } }

    it 'returns the evidence pipeline' do
      expect(subject).to eq(pipeline)
    end
  end

  context 'when the ref is passed' do
    let(:params) { { ref: sha } }

    it 'returns the evidence pipeline' do
      expect(subject).to eq(pipeline)
    end
  end

  context 'empty params' do
    it 'returns nil' do
      expect(subject).to be_nil
    end
  end

  # TODO: remove this with the release creation moved to it's own form https://gitlab.com/gitlab-org/gitlab/-/issues/214245
  context 'params[:evidence_pipeline] is present' do
    let(:params) { { evidence_pipeline: pipeline } }

    it 'returns the passed evidence pipeline' do
      expect(subject).to eq(pipeline)
    end
  end
end
