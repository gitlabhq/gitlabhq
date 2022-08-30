# frozen_string_literal: true

RSpec.describe QA::Tools::Ci::QaChanges do
  subject(:qa_changes) { described_class.new(mr_diff, mr_labels) }

  let(:mr_labels) { [] }

  before do
    allow(File).to receive(:directory?).and_return(false)
  end

  context "with spec only changes" do
    let(:mr_diff) do
      [
        { path: "qa/qa/specs/features/test_spec.rb", diff: "" },
        { path: "qa/qa/specs/features/another_test_spec.rb", diff: "" }
      ]
    end

    it ".qa_tests return changed specs" do
      expect(qa_changes.qa_tests).to eq(
        "qa/specs/features/test_spec.rb qa/specs/features/another_test_spec.rb"
      )
    end

    it ".framework_changes? return false" do
      expect(qa_changes.framework_changes?).to eq(false)
    end

    it ".quarantine_changes? return false" do
      expect(qa_changes.quarantine_changes?).to eq(false)
    end
  end

  context "with framework changes" do
    let(:mr_diff) { [{ path: "qa/qa.rb" }] }

    it ".qa_tests do not return specifix specs" do
      expect(qa_changes.qa_tests).to be_nil
    end

    it ".framework_changes? return true" do
      expect(qa_changes.framework_changes?).to eq(true)
    end

    it ".quarantine_changes? return false" do
      expect(qa_changes.quarantine_changes?).to eq(false)
    end
  end

  context "with non qa changes" do
    let(:mr_diff) { [{ path: "Gemfile" }] }

    it ".framework_changes? return false" do
      expect(qa_changes.framework_changes?).to eq(false)
    end

    it ".quarantine_changes? return false" do
      expect(qa_changes.quarantine_changes?).to eq(false)
    end

    context "without mr labels" do
      it ".qa_tests do not return any specific specs" do
        expect(qa_changes.qa_tests).to be_nil
      end
    end

    context "with mr label" do
      let(:mr_labels) { ["devops::manage"] }

      it ".qa_tests return specs for devops stage" do
        expect(qa_changes.qa_tests.split(" ")).to include(
          "qa/specs/features/browser_ui/1_manage/",
          "qa/specs/features/api/1_manage/"
        )
      end
    end
  end

  context "with quarantine changes" do
    let(:mr_diff) { [{ path: "qa/qa/specs/features/test_spec.rb", diff: "+ , quarantine: true" }] }

    it ".quarantine_changes? return true" do
      expect(qa_changes.quarantine_changes?).to eq(true)
    end
  end
end
