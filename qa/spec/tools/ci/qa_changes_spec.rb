# frozen_string_literal: true

require "fog/google"

RSpec.describe QA::Tools::Ci::QaChanges do
  include QA::Support::Helpers::StubEnv
  subject(:qa_changes) { described_class.new(mr_diff) }

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
        ["qa/specs/features/test_spec.rb", "qa/specs/features/another_test_spec.rb"]
      )
    end

    it ".framework_changes? return false" do
      expect(qa_changes.framework_changes?).to be(false)
    end

    it ".quarantine_changes? return false" do
      expect(qa_changes.quarantine_changes?).to be(false)
    end
  end

  context "with only unit test changes" do
    let(:mr_diff) do
      [
        { path: "spec/features/test_spec.rb", diff: "" },
        { path: "ee/spec/features/another_test_spec.rb", diff: "" }
      ]
    end

    it ".only_changes_to_non_e2e_spec_files? returns true" do
      expect(qa_changes.only_changes_to_non_e2e_spec_files?).to be(true)
    end
  end

  context "with framework changes" do
    let(:mr_diff) { [{ path: "qa/qa.rb" }] }

    it ".qa_tests do not return specific specs" do
      expect(qa_changes.qa_tests).to be_empty
    end

    it ".framework_changes? return true" do
      expect(qa_changes.framework_changes?).to be(true)
    end

    it ".quarantine_changes? return false" do
      expect(qa_changes.quarantine_changes?).to be(false)
    end
  end

  context "with shared example changes" do
    let(:mr_diff) { [{ path: "qa/qa/specs/features/shared_context/some_context.rb", diff: "" }] }

    it ".qa_tests do not return specific specs" do
      expect(qa_changes.qa_tests).to be_empty
    end
  end

  context "with empty diff" do
    let(:mr_diff) { [] }

    it ".framework_changes? return false" do
      expect(qa_changes.framework_changes?).to be(false)
    end

    it ".quarantine_changes? return false" do
      expect(qa_changes.quarantine_changes?).to be(false)
    end

    it ".only_spec_removal? return false" do
      expect(qa_changes.only_spec_removal?).to be(false)
    end

    it ".qa_tests returns empty array" do
      expect(qa_changes.qa_tests).to eq([])
    end

    it ".only_changes_to_non_e2e_spec_files? returns false" do
      expect(qa_changes.only_changes_to_non_e2e_spec_files?).to be(false)
    end
  end

  context "with non qa changes" do
    let(:mr_diff) { [{ path: "Gemfile" }] }

    it ".framework_changes? return false" do
      expect(qa_changes.framework_changes?).to be(false)
    end

    it ".quarantine_changes? return false" do
      expect(qa_changes.quarantine_changes?).to be(false)
    end

    context "with from_code_path_mapping option for #qa_tests" do
      let(:code_paths_mapping_data) do
        {
          "./qa/specs/features/test_spec.rb:23" => %w[./lib/model.rb ./lib/second.rb],
          "./qa/specs/features/test_spec_2.rb:11" => ['./app/controller.rb']
        }
      end

      let(:selected_specs) { ["qa/specs/features/test_spec.rb"] }
      let(:gcs_project_id) { 'gitlab-qa-resources' }
      let(:gcs_creds) { 'gcs-creds' }
      let(:gcs_bucket_name) { 'metrics-gcs-bucket' }
      let(:gcs_client) { double("Fog::Google::StorageJSON::Real", put_object: nil) } # rubocop:disable RSpec/VerifiedDoubles -- instance_double complains put_object is not implemented but it is

      let(:code_paths_mapping) do
        instance_double(QA::Tools::Ci::CodePathsMapping, import: code_paths_mapping_data)
      end

      before do
        stub_env('QA_CODE_PATH_MAPPINGS_GCS_CREDENTIALS', gcs_creds)

        allow(QA::Tools::Ci::CodePathsMapping).to receive(:new).and_return(code_paths_mapping)
        allow(Fog::Google::Storage).to receive(:new)
          .with(google_project: gcs_project_id, google_json_key_string: gcs_creds)
          .and_return(gcs_client)
      end

      context 'when there is a match from code paths mapping' do
        let(:mr_diff) { [{ path: 'lib/model.rb' }] }

        it "returns specific specs" do
          expect(qa_changes.qa_tests(from_code_path_mapping: true)).to eq(selected_specs)
        end
      end

      context 'when there is no match from code paths mapping' do
        let(:mr_diff) { [{ path: 'lib/new.rb' }] }

        it "returns nil" do
          expect(qa_changes.qa_tests(from_code_path_mapping: true)).to be_empty
        end
      end

      context 'when code paths mapping import returns nil' do
        let(:mr_diff) { [{ path: 'lib/model.rb' }] }
        let(:code_paths_mapping) do
          instance_double(QA::Tools::Ci::CodePathsMapping, import: nil)
        end

        it "does not throw an error" do
          expect(qa_changes.qa_tests(from_code_path_mapping: true)).to be_empty
        end
      end

      context "with frontend selective execution" do
        let(:frontend_code_paths_mapping_data) do
          {
            "./qa/specs/features/browser_ui/1_manage/project/create_project_spec.rb:123" =>
              %w[/builds/gitlab-org/gitlab/app/assets/javascripts/projects/new/index.js /builds/gitlab-org/
                gitlab/app/views/projects/new.html.haml],
            "./qa/specs/features/browser_ui/2_plan/issue/create_issue_spec.rb:45" => [
              "/builds/gitlab-org/gitlab/app/assets/javascripts/issues/new/index.js"
            ]
          }
        end

        let(:backend_code_paths_mapping_data) do
          {
            "./qa/specs/features/api/test_spec.rb:23" => ["./lib/model.rb"],
            "./qa/specs/features/ui/test_spec_2.rb:11" => ["./app/controller.rb"]
          }
        end

        let(:frontend_code_paths_mapping) do
          instance_double(QA::Tools::Ci::CodePathsMapping, import: frontend_code_paths_mapping_data)
        end

        let(:backend_code_paths_mapping) do
          instance_double(QA::Tools::Ci::CodePathsMapping, import: backend_code_paths_mapping_data)
        end

        before do
          stub_env('QA_CODE_PATH_MAPPINGS_GCS_CREDENTIALS', 'gcs-creds')
          stub_env('FRONTEND_SELECTIVE_EXECUTION', 'true')
          allow(QA::Tools::Ci::CodePathsMapping).to receive(:new).and_return(backend_code_paths_mapping,
            frontend_code_paths_mapping)
        end

        context "with frontend file changes" do
          let(:mr_diff) { [{ path: 'app/assets/javascripts/projects/new/index.js' }] }

          it "returns frontend-related specs from code paths mapping" do
            result = qa_changes.qa_tests(from_code_path_mapping: true)
            expect(result).to include("qa/specs/features/browser_ui/1_manage/project/create_project_spec.rb")
          end
        end

        context "with backend file changes" do
          let(:mr_diff) { [{ path: 'lib/model.rb' }] }

          it "returns backend-related specs from code paths mapping" do
            result = qa_changes.qa_tests(from_code_path_mapping: true)
            expect(result).to include("qa/specs/features/api/test_spec.rb")
          end
        end

        context "with both frontend and backend file changes" do
          let(:mr_diff) do
            [
              { path: 'app/assets/javascripts/projects/new/index.js' },
              { path: 'lib/model.rb' }
            ]
          end

          it "returns both frontend and backend specs without duplicates" do
            result = qa_changes.qa_tests(from_code_path_mapping: true)
            expect(result).to include(
              "qa/specs/features/browser_ui/1_manage/project/create_project_spec.rb",
              "qa/specs/features/api/test_spec.rb"
            )
            expect(result.uniq.length).to eq(result.length)
          end
        end
      end
    end
  end

  context "with quarantine changes" do
    let(:mr_diff) { [{ path: "qa/qa/specs/features/test_spec.rb", diff: "+ , quarantine: true" }] }

    it ".quarantine_changes? return true" do
      expect(qa_changes.quarantine_changes?).to be(true)
    end
  end

  %w[GITALY_SERVER_VERSION Gemfile.lock yarn.lock Dockerfile.assets].each do |dependency_file|
    context "when #{dependency_file} change" do
      let(:mr_diff) { [{ path: dependency_file }] }

      it ".qa_tests do not return specific specs" do
        expect(qa_changes.qa_tests).to be_empty
      end
    end
  end
end
