# frozen_string_literal: true

RSpec.describe QA::Tools::Ci::FfChanges do
  subject(:ff_changes) { described_class.new(mr_diff) }

  before do
    allow(Gitlab::QA::TestLogger).to receive(:logger).and_return(Logger.new(StringIO.new))
  end

  context "with merge request pipeline" do
    let(:deleted_file) { false }
    let(:mr_diff) do
      [
        {
          path: "config/feature_flags/development/async_commit_diff_files.yml",
          deleted_file: deleted_file
        }
      ]
    end

    before do
      allow(File).to receive(:read)
        .with(File.expand_path("../#{mr_diff.first[:path]}", QA::Runtime::Path.qa_root))
        .and_return(File.read("spec/fixtures/ff/async_commit_diff_files.yml"))
    end

    context "with changed feature flag" do
      it "returns inverse ff state option" do
        expect(ff_changes.fetch).to eq("async_commit_diff_files=enabled")
      end
    end

    context 'with feature flags outside of development and ops' do
      let(:mr_diff) do
        [
          {
            path: "config/feature_flags/gitlab_com_derisk/async_commit_diff_files.yml",
            deleted_filed: false
          }
        ]
      end

      it "returns inverse ff state option" do
        expect(ff_changes.fetch).to eq("async_commit_diff_files=enabled")
      end
    end

    context "with deleted feature flag" do
      let(:deleted_file) { true }

      it "returns deleted ff state option" do
        expect(ff_changes.fetch).to eq("async_commit_diff_files=deleted")
      end
    end
  end

  context "without merge request pipeline" do
    let(:mr_diff) { [] }

    context "with empty mr diff" do
      it "doesn't return any ff options" do
        expect(ff_changes.fetch).to be_nil
      end
    end
  end
end
