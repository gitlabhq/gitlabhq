require 'spec_helper'

describe ArtifactHelper do
  set(:job) { create(:ci_build, :artifacts) }

  let(:html_entry) { job.artifacts_metadata_entry("other_artifacts_0.1.2/index.html") }
  let(:txt_entry) { job.artifacts_metadata_entry("other_artifacts_0.1.2/doc_sample.txt") }

  before do
    allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
    allow(Gitlab.config.pages).to receive(:artifacts_server).and_return(true)
  end

  describe '#link_to_artifact' do
    context 'link_to_pages returns true' do
      subject { link_to_artifact(job.project, job, entry) }

      before do
        allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
      end

      context 'when the entry is HTML' do
        let(:entry) { html_entry }

        it { is_expected.to match Gitlab.config.pages.host }
        it { is_expected.to match /-\/jobs\/\d+\/artifacts/ }
      end

      context 'when the entry is not HTML' do
        let(:entry) { txt_entry }

        it { is_expected.not_to match Gitlab.config.pages.host }
      end
    end
  end

  describe '#external_url?' do
    context 'pages enabled' do
      before do
        allow(Gitlab.config.pages).to receive(:artifacts_server).and_return(true)
      end

      it 'returns true for HTML files' do
        expect(external_url?(txt_entry.blob)).to be(false)
      end

      it 'returns true for HTML files' do
        expect(external_url?(html_entry.blob)).to be(true)
      end
    end
  end
end
