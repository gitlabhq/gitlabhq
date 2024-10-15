# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SecretDetection::ScanDiffs, feature_category: :secret_detection do
  subject(:scan) { described_class.new }

  let(:diff_blob) do
    Struct.new(:left_blob_id, :right_blob_id, :patch, :status, :binary, :over_patch_bytes_limit, keyword_init: true)
  end

  let(:sha1_blank_sha) { ('0' * 40).freeze }
  let(:sample_blob_id) { 'fe29d93da4843da433e62711ace82db601eb4f8f' }

  let(:exclusion) do
    Struct.new(:value, keyword_init: true)
  end

  let(:ruleset) do
    {
      "title" => "gitleaks config",
      "rules" => [
        {
          "id" => "gitlab_personal_access_token",
          "description" => "GitLab Personal Access Token",
          "regex" => "\bglpat-[0-9a-zA-Z_-]{20}\b",
          "tags" => %w[gitlab revocation_type],
          "keywords" => ["glpat"]
        },
        {
          "id" => "gitlab_pipeline_trigger_token",
          "description" => "GitLab Pipeline Trigger Token",
          "regex" => "\bglptt-[0-9a-zA-Z_-]{40}\b",
          "tags" => ["gitlab"],
          "keywords" => ["glptt"]
        },
        {
          "id" => "gitlab_runner_registration_token",
          "description" => "GitLab Runner Registration Token",
          "regex" => "\bGR1348941[0-9a-zA-Z_-]{20}\b",
          "tags" => ["gitlab"],
          "keywords" => ["GR1348941"]
        },
        {
          "id" => "gitlab_feed_token_v2",
          "description" => "GitLab Feed token",
          "regex" => "\bglft-[0-9a-zA-Z_-]{20}\b",
          "tags" => ["gitlab"],
          "keywords" => ["glft"]
        }
      ]
    }
  end

  it "does not raise an error parsing the toml file" do
    expect { scan }.not_to raise_error
  end

  context "when it creates RE2 patterns from file data" do
    before do
      allow(scan).to receive(:parse_ruleset).and_return(ruleset)
    end

    it "does not raise an error when building patterns" do
      expect { scan }.not_to raise_error
    end
  end

  context "when matching patterns" do
    before do
      allow(scan).to receive(:parse_ruleset).and_return(ruleset)
    end

    context 'when the diff does not contain a secret' do
      let(:diffs) do
        [
          diff_blob.new(
            left_blob_id: sha1_blank_sha,
            right_blob_id: sample_blob_id,
            patch: "@@ -0,0 +1 @@\n+BASE_URL=https://foo.bar\n\\ No newline at end of file\n",
            status: :STATUS_END_OF_PATCH,
            binary: false,
            over_patch_bytes_limit: false
          )
        ]
      end

      it "does not match" do
        expected_response = Gitlab::SecretDetection::Response.new(Gitlab::SecretDetection::Status::NOT_FOUND)

        expect(scan.secrets_scan(diffs)).to eq(expected_response)
      end

      it "attempts to keyword match returning no diffs for further scan" do
        expect(scan).to receive(:filter_by_keywords)
          .with(diffs)
          .and_return([])

        scan.secrets_scan(diffs)
      end

      it "does not attempt to regex match" do
        expect(scan).not_to receive(:match_rules_bulk)

        scan.secrets_scan(diffs)
      end
    end

    context "when multiple diffs contains secrets" do
      let(:diffs) do
        [
          diff_blob.new(
            left_blob_id: sha1_blank_sha,
            right_blob_id: sample_blob_id,
            patch: "@@ -0,0 +1 @@\n+glpat-12312312312312312312\n", # gitleaks:allow
            status: :STATUS_END_OF_PATCH,
            binary: false,
            over_patch_bytes_limit: false
          ),
          diff_blob.new(
            left_blob_id: sha1_blank_sha,
            right_blob_id: sample_blob_id,
            patch: "@@ -0,0 +1,3 @@\n+\n+\n+glptt-1231231231231231231212312312312312312312\n", # gitleaks:allow
            status: :STATUS_END_OF_PATCH,
            binary: false,
            over_patch_bytes_limit: false
          ),
          diff_blob.new(
            left_blob_id: sha1_blank_sha,
            right_blob_id: sample_blob_id,
            patch: "@@ -0,0 +1 @@\n+data with no secret\n",
            status: :STATUS_END_OF_PATCH,
            binary: false,
            over_patch_bytes_limit: false
          ),
          diff_blob.new(
            left_blob_id: sha1_blank_sha,
            right_blob_id: sample_blob_id,
            patch: "@@ -0,0 +1,2 @@\n+GR134894112312312312312312312\n+glft-12312312312312312312\n", # gitleaks:allow
            status: :STATUS_END_OF_PATCH,
            binary: false,
            over_patch_bytes_limit: false
          ),
          diff_blob.new(
            left_blob_id: sha1_blank_sha,
            right_blob_id: sample_blob_id,
            patch: "@@ -0,0 +1 @@\n+data with no secret\n",
            status: :STATUS_END_OF_PATCH,
            binary: false,
            over_patch_bytes_limit: false
          ),
          diff_blob.new(
            left_blob_id: sha1_blank_sha,
            right_blob_id: sample_blob_id,
            patch: "@@ -0,0 +1 @@\n+data with no secret\n",
            status: :STATUS_END_OF_PATCH,
            binary: false,
            over_patch_bytes_limit: false
          ),
          diff_blob.new(
            left_blob_id: sha1_blank_sha,
            right_blob_id: sample_blob_id,
            patch: "@@ -0,0 +1 @@\n+glptt-1231231231231231231212312312312312312312\n", # gitleaks:allow
            status: :STATUS_END_OF_PATCH,
            binary: false,
            over_patch_bytes_limit: false
          ),
          diff_blob.new(
            left_blob_id: sha1_blank_sha,
            right_blob_id: sample_blob_id,
            patch: "@@ -0,0 +1,2 @@\n+glpat-12312312312312312312\n+GR134894112312312312312312312\n", # gitleaks:allow
            status: :STATUS_END_OF_PATCH,
            binary: false,
            over_patch_bytes_limit: false
          )
        ]
      end

      let(:expected_response) do
        Gitlab::SecretDetection::Response.new(
          Gitlab::SecretDetection::Status::FOUND,
          [
            Gitlab::SecretDetection::Finding.new(
              diffs[0].right_blob_id,
              Gitlab::SecretDetection::Status::FOUND,
              1,
              ruleset['rules'][0]['id'],
              ruleset['rules'][0]['description']
            ),
            Gitlab::SecretDetection::Finding.new(
              diffs[1].right_blob_id,
              Gitlab::SecretDetection::Status::FOUND,
              3,
              ruleset['rules'][1]['id'],
              ruleset['rules'][1]['description']
            ),
            Gitlab::SecretDetection::Finding.new(
              diffs[3].right_blob_id,
              Gitlab::SecretDetection::Status::FOUND,
              1,
              ruleset['rules'][2]['id'],
              ruleset['rules'][2]['description']
            ),
            Gitlab::SecretDetection::Finding.new(
              diffs[3].right_blob_id,
              Gitlab::SecretDetection::Status::FOUND,
              2,
              ruleset['rules'][3]['id'],
              ruleset['rules'][3]['description']
            ),
            Gitlab::SecretDetection::Finding.new(
              diffs[6].right_blob_id,
              Gitlab::SecretDetection::Status::FOUND,
              1,
              ruleset['rules'][1]['id'],
              ruleset['rules'][1]['description']
            ),
            Gitlab::SecretDetection::Finding.new(
              diffs[7].right_blob_id,
              Gitlab::SecretDetection::Status::FOUND,
              1,
              ruleset['rules'][0]['id'],
              ruleset['rules'][0]['description']
            ),
            Gitlab::SecretDetection::Finding.new(
              diffs[7].right_blob_id,
              Gitlab::SecretDetection::Status::FOUND,
              2,
              ruleset['rules'][2]['id'],
              ruleset['rules'][2]['description']
            )
          ]
        )
      end

      it "attempts to keyword match returning only filtered diffs for further scan" do
        expected = diffs.reject { |d| d.patch.include?("data with no secret") }

        expect(scan).to receive(:filter_by_keywords)
                          .with(diffs)
                          .and_return(expected)

        scan.secrets_scan(diffs)
      end

      it "matches multiple rules when running in main process" do
        expect(scan.secrets_scan(diffs, subprocess: false)).to eq(expected_response)
      end
    end

    context "when configured with time out" do
      let(:each_payload_timeout_secs) { 0.000_001 } # 1 micro-sec to intentionally timeout large diff

      let(:large_data) do
        ("\n+large data with a secret glpat-12312312312312312312" * 10_000_000).freeze # gitleaks:allow
      end

      let(:diffs) do
        [
          diff_blob.new(
            left_blob_id: sha1_blank_sha,
            right_blob_id: sample_blob_id,
            patch: "@@ -0,0 +1,2 @@\n+GR134894112312312312312312312\n", # gitleaks:allow
            status: :STATUS_END_OF_PATCH,
            binary: false,
            over_patch_bytes_limit: false
          ),
          diff_blob.new(
            left_blob_id: sha1_blank_sha,
            right_blob_id: sample_blob_id,
            patch: "@@ -0,0 +1,2 @@\n+data with no secret\n",
            status: :STATUS_END_OF_PATCH,
            binary: false,
            over_patch_bytes_limit: false
          ),
          diff_blob.new(
            left_blob_id: sha1_blank_sha,
            right_blob_id: sample_blob_id,
            patch: "@@ -0,0 +1,10000001 @@\n#{large_data}\n",
            status: :STATUS_END_OF_PATCH,
            binary: false,
            over_patch_bytes_limit: false
          )
        ]
      end

      let(:all_large_diffs) do
        [
          diff_blob.new(
            left_blob_id: sha1_blank_sha,
            right_blob_id: sample_blob_id,
            patch: "@@ -0,0 +1,10000001 @@\n#{large_data}\n",
            status: :STATUS_END_OF_PATCH,
            binary: false,
            over_patch_bytes_limit: false
          ),
          diff_blob.new(
            left_blob_id: sha1_blank_sha,
            right_blob_id: sample_blob_id,
            patch: "@@ -0,0 +1,10000001 @@\n#{large_data}\n",
            status: :STATUS_END_OF_PATCH,
            binary: false,
            over_patch_bytes_limit: false
          ),
          diff_blob.new(
            left_blob_id: sha1_blank_sha,
            right_blob_id: sample_blob_id,
            patch: "@@ -0,0 +1,10000001 @@\n#{large_data}\n",
            status: :STATUS_END_OF_PATCH,
            binary: false,
            over_patch_bytes_limit: false
          )
        ]
      end

      it "whole secret detection scan operation times out" do
        scan_timeout_secs = 0.000_001 # 1 micro-sec to intentionally timeout large diff

        expected_response = Gitlab::SecretDetection::Response.new(Gitlab::SecretDetection::Status::SCAN_TIMEOUT)

        begin
          response = scan.secrets_scan(diffs, timeout: scan_timeout_secs)
          expect(response).to eq(expected_response)
        rescue ArgumentError
          # When RSpec's main process terminates and attempts to clean up child processes upon completion, it terminates
          # subprocesses where the scans might be still ongoing. This behavior is not recognized by the
          # upstream library (parallel), which manages all forked subprocesses it created for running scans. When the
          # upstream library attempts to close its forked subprocesses which already terminated, it raises an
          # 'ArgumentError' with the message 'bad signal type NilClass,' resulting in flaky failures in the test
          # expectations.
          #
          # Example: https://gitlab.com/gitlab-org/gitlab/-/jobs/6935051992
          #
          puts "skipping the test since the subprocesses forked for SD scanning are terminated by main process"
        end
      end

      it "one of the diffs times out while others continue to get scanned" do
        expected_response = Gitlab::SecretDetection::Response.new(
          Gitlab::SecretDetection::Status::FOUND_WITH_ERRORS,
          [
            Gitlab::SecretDetection::Finding.new(
              diffs[0].right_blob_id,
              Gitlab::SecretDetection::Status::FOUND,
              1,
              ruleset['rules'][2]['id'],
              ruleset['rules'][2]['description']
            ),
            Gitlab::SecretDetection::Finding.new(
              diffs[2].right_blob_id,
              Gitlab::SecretDetection::Status::PAYLOAD_TIMEOUT
            )
          ]
        )

        expect(scan.secrets_scan(diffs, payload_timeout: each_payload_timeout_secs)).to eq(expected_response)
      end

      it "all the diffs time out" do
        # scan status changes to SCAN_TIMEOUT when *all* the diffs time out
        expected_scan_status = Gitlab::SecretDetection::Status::SCAN_TIMEOUT

        expected_response = Gitlab::SecretDetection::Response.new(
          expected_scan_status,
          [
            Gitlab::SecretDetection::Finding.new(
              all_large_diffs[0].right_blob_id,
              Gitlab::SecretDetection::Status::PAYLOAD_TIMEOUT
            ),
            Gitlab::SecretDetection::Finding.new(
              all_large_diffs[1].right_blob_id,
              Gitlab::SecretDetection::Status::PAYLOAD_TIMEOUT
            ),
            Gitlab::SecretDetection::Finding.new(
              all_large_diffs[2].right_blob_id,
              Gitlab::SecretDetection::Status::PAYLOAD_TIMEOUT
            )
          ]
        )

        expect(scan.secrets_scan(all_large_diffs, payload_timeout: each_payload_timeout_secs)).to eq(expected_response)
      end
    end

    context 'when using exclusions' do
      let(:diffs) do
        [
          diff_blob.new(
            left_blob_id: sha1_blank_sha,
            right_blob_id: sample_blob_id,
            patch: "@@ -0,0 +1 @@\n+data with no secret\n",
            status: :STATUS_END_OF_PATCH,
            binary: false,
            over_patch_bytes_limit: false
          ),
          diff_blob.new(
            left_blob_id: sha1_blank_sha,
            right_blob_id: sample_blob_id,
            patch: "@@ -0,0 +1 @@\n+GR134894145645645645645645645\n", # gitleaks:allow
            status: :STATUS_END_OF_PATCH,
            binary: false,
            over_patch_bytes_limit: false
          ),
          diff_blob.new(
            left_blob_id: sha1_blank_sha,
            right_blob_id: sample_blob_id,
            patch: "@@ -0,0 +1 @@\n+GR134894145645645645645645789\n", # gitleaks:allow
            status: :STATUS_END_OF_PATCH,
            binary: false,
            over_patch_bytes_limit: false
          ),
          diff_blob.new(
            left_blob_id: sha1_blank_sha,
            right_blob_id: sample_blob_id,
            patch: "@@ -0,0 +1 @@\n+GR134894112312312312312312312\n", # gitleaks:allow
            status: :STATUS_END_OF_PATCH,
            binary: false,
            over_patch_bytes_limit: false
          ),
          diff_blob.new(
            left_blob_id: sha1_blank_sha,
            right_blob_id: sample_blob_id,
            patch: "@@ -0,0 +1 @@\n+glpat-12312312312312312312\n", # gitleaks:allow
            status: :STATUS_END_OF_PATCH,
            binary: false,
            over_patch_bytes_limit: false
          ),
          diff_blob.new(
            left_blob_id: sha1_blank_sha,
            right_blob_id: sample_blob_id,
            patch: "@@ -0,0 +1,3 @@\n+test data" \
                   "\n+glptt-1231231231231231231212312312312312312312\n+line contd", # gitleaks:allow
            status: :STATUS_END_OF_PATCH,
            binary: false,
            over_patch_bytes_limit: false
          )
        ]
      end

      context "when excluding secrets based on raw values" do
        let(:exclusions) do
          {
            raw_value: [
              exclusion.new(value: 'GR134894112312312312312312312'), # gitleaks:allow
              exclusion.new(value: 'glpat-12312312312312312312') # gitleaks:allow
            ]
          }
        end

        let(:valid_lines) do
          [
            diffs[1].patch,
            diffs[2].patch,
            *diffs[5].patch.lines
          ]
        end

        it "excludes values from being detected" do
          expected_scan_status = Gitlab::SecretDetection::Status::FOUND

          expected_response = Gitlab::SecretDetection::Response.new(
            expected_scan_status,
            [
              Gitlab::SecretDetection::Finding.new(
                diffs[1].right_blob_id,
                expected_scan_status,
                1,
                ruleset['rules'][2]['id'],
                ruleset['rules'][2]['description']
              ),
              Gitlab::SecretDetection::Finding.new(
                diffs[2].right_blob_id,
                expected_scan_status,
                1,
                ruleset['rules'][2]['id'],
                ruleset['rules'][2]['description']
              ),
              Gitlab::SecretDetection::Finding.new(
                diffs[5].right_blob_id,
                expected_scan_status,
                2,
                ruleset['rules'][1]['id'],
                ruleset['rules'][1]['description']
              )
            ]
          )

          expect(scan.secrets_scan(diffs, exclusions: exclusions)).to eq(expected_response)
        end
      end

      context "when excluding secrets based on rules from default ruleset" do
        let(:exclusions) do
          {
            rule: [
              exclusion.new(value: "gitlab_runner_registration_token"),
              exclusion.new(value: "gitlab_personal_access_token")
            ]
          }
        end

        it 'filters out secrets matching excluded rules from detected findings' do
          expected_scan_status = Gitlab::SecretDetection::Status::FOUND

          expected_response = Gitlab::SecretDetection::Response.new(
            expected_scan_status,
            [
              Gitlab::SecretDetection::Finding.new(
                diffs[5].right_blob_id,
                expected_scan_status,
                2,
                ruleset['rules'][1]['id'],
                ruleset['rules'][1]['description']
              )
            ]
          )

          expect(scan.secrets_scan(diffs, exclusions: exclusions)).to eq(expected_response)
        end
      end
    end
  end
end
