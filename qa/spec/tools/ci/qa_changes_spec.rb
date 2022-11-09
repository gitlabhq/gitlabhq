# frozen_string_literal: true

RSpec.describe QA::Tools::Ci::QaChanges do
  subject(:qa_changes) { described_class.new(mr_diff, mr_labels, additional_group_spec_list) }

  let(:mr_labels) { [] }
  let(:additional_group_spec_list) { [] }

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

    it ".qa_tests do not return specific specs" do
      expect(qa_changes.qa_tests).to be_nil
    end

    it ".framework_changes? return true" do
      expect(qa_changes.framework_changes?).to eq(true)
    end

    it ".quarantine_changes? return false" do
      expect(qa_changes.quarantine_changes?).to eq(false)
    end
  end

  context "with shared example changes" do
    let(:mr_diff) { [{ path: "qa/qa/specs/features/shared_context/some_context.rb", diff: "" }] }

    it ".qa_tests do not return specific specs" do
      expect(qa_changes.qa_tests).to be_nil
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

    context "when configured to run tests from other stages" do
      let(:additional_group_spec_list) do
        {
          'foo' => %w[create],
          'bar' => %w[monitor verify]
        }
      end

      context "with a single extra stage configured for the group name" do
        let(:mr_labels) { %w[devops::manage group::foo] }

        it ".qa_tests return specs for both devops stage and create stage" do
          expect(qa_changes.qa_tests.split(" ")).to include(
            "qa/specs/features/browser_ui/1_manage/",
            "qa/specs/features/api/1_manage/",
            "qa/specs/features/browser_ui/3_create/",
            "qa/specs/features/api/3_create/"
          )
        end
      end

      context "with a multiple extra stages configured for the group name" do
        let(:mr_labels) { %w[devops::manage group::bar] }

        it ".qa_tests return specs for both devops stage and multiple other stages" do
          expect(qa_changes.qa_tests.split(" ")).to include(
            "qa/specs/features/browser_ui/1_manage/",
            "qa/specs/features/api/1_manage/",
            "qa/specs/features/browser_ui/8_monitor/",
            "qa/specs/features/api/8_monitor/",
            "qa/specs/features/browser_ui/4_verify/",
            "qa/specs/features/api/4_verify/"
          )
        end
      end
    end
  end

  context "with quarantine changes" do
    let(:mr_diff) { [{ path: "qa/qa/specs/features/test_spec.rb", diff: "+ , quarantine: true" }] }

    it ".quarantine_changes? return true" do
      expect(qa_changes.quarantine_changes?).to eq(true)
    end
  end

  %w[GITALY_SERVER_VERSION Gemfile.lock yarn.lock Dockerfile.assets].each do |dependency_file|
    context "when #{dependency_file} change" do
      let(:mr_diff) { [{ path: dependency_file }] }

      it ".qa_tests do not return specific specs" do
        expect(qa_changes.qa_tests).to be_nil
      end
    end
  end
end
