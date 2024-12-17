# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SecretDetection::Scan, feature_category: :secret_detection do
  subject(:scan) { described_class.new }

  def new_payload(id:, data:, offset:)
    { id:, data:, offset: }
  end

  let(:exclusion) do
    Struct.new('Exclusion', :value, :keyword_init)
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

  let(:empty_applied_exclusions) { [] }

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

    context 'when the payload does not contain a secret' do
      let(:payloads) do
        [
          new_payload(id: 1234, data: "no secrets", offset: 1)
        ]
      end

      it "does not match" do
        expected_response = Gitlab::SecretDetection::Response.new(
          Gitlab::SecretDetection::Status::NOT_FOUND,
          nil,
          empty_applied_exclusions
        )

        expect(scan.secrets_scan(payloads)).to eq(expected_response)
      end

      it "attempts to keyword match returning no payloads for further scan" do
        expect(scan).to receive(:filter_by_keywords)
          .with(payloads)
          .and_return([])

        scan.secrets_scan(payloads)
      end

      it "does not attempt to regex match" do
        expect(scan).not_to receive(:match_rules_bulk)

        scan.secrets_scan(payloads)
      end
    end

    context "when multiple payloads contains secrets" do
      let(:payloads) do
        [
          new_payload(id: 111, data: "glpat-12312312312312312312", offset: 1), # gitleaks:allow
          new_payload(id: 222, data: "\n\nglptt-1231231231231231231212312312312312312312", offset: 1), # gitleaks:allow
          new_payload(id: 333, data: "data with no secret", offset: 1),
          new_payload(id: 444,
            data: "GR134894112312312312312312312\nglft-12312312312312312312", offset: 1), # gitleaks:allow
          new_payload(id: 555, data: "data with no secret", offset: 1),
          new_payload(id: 666, data: "data with no secret", offset: 1),
          new_payload(id: 777, data: "\nglptt-1231231231231231231212312312312312312312", offset: 1), # gitleaks:allow
          new_payload(id: 888,
            data: "glpat-12312312312312312312;GR134894112312312312312312312", offset: 1) # gitleaks:allow
        ]
      end

      let(:expected_response) do
        Gitlab::SecretDetection::Response.new(
          Gitlab::SecretDetection::Status::FOUND,
          [
            Gitlab::SecretDetection::Finding.new(
              payloads[0][:id],
              Gitlab::SecretDetection::Status::FOUND,
              1,
              ruleset['rules'][0]['id'],
              ruleset['rules'][0]['description']
            ),
            Gitlab::SecretDetection::Finding.new(
              payloads[1][:id],
              Gitlab::SecretDetection::Status::FOUND,
              3,
              ruleset['rules'][1]['id'],
              ruleset['rules'][1]['description']
            ),
            Gitlab::SecretDetection::Finding.new(
              payloads[3][:id],
              Gitlab::SecretDetection::Status::FOUND,
              1,
              ruleset['rules'][2]['id'],
              ruleset['rules'][2]['description']
            ),
            Gitlab::SecretDetection::Finding.new(
              payloads[3][:id],
              Gitlab::SecretDetection::Status::FOUND,
              2,
              ruleset['rules'][3]['id'],
              ruleset['rules'][3]['description']
            ),
            Gitlab::SecretDetection::Finding.new(
              payloads[6][:id],
              Gitlab::SecretDetection::Status::FOUND,
              2,
              ruleset['rules'][1]['id'],
              ruleset['rules'][1]['description']
            ),
            Gitlab::SecretDetection::Finding.new(
              payloads[7][:id],
              Gitlab::SecretDetection::Status::FOUND,
              1,
              ruleset['rules'][0]['id'],
              ruleset['rules'][0]['description']
            ),
            Gitlab::SecretDetection::Finding.new(
              payloads[7][:id],
              Gitlab::SecretDetection::Status::FOUND,
              1,
              ruleset['rules'][2]['id'],
              ruleset['rules'][2]['description']
            )
          ],
          empty_applied_exclusions
        )
      end

      it "attempts to keyword match returning only filtered payloads for further scan" do
        expected = payloads.filter { |b| b[:data] != "data with no secret" }

        expect(scan).to receive(:filter_by_keywords)
                          .with(payloads)
                          .and_return(expected)

        scan.secrets_scan(payloads)
      end

      it "matches multiple rules when running in main process" do
        expect(scan.secrets_scan(payloads, subprocess: false)).to eq(expected_response)
      end

      context "in subprocess" do
        let(:dummy_lines) do
          10_000
        end

        let(:large_payloads) do
          dummy_data = "\nrandom data" * dummy_lines
          [
            new_payload(id: 111, data: "glpat-12312312312312312312#{dummy_data}", offset: 1), # gitleaks:allow
            new_payload(
              id: 222,
              data: "\n\nglptt-1231231231231231231212312312312312312312#{dummy_data}", # gitleaks:allow
              offset: 1
            ),
            new_payload(id: 333, data: "data with no secret#{dummy_data}", offset: 1),
            new_payload(
              id: 444,
              data: "GR134894112312312312312312312\nglft-12312312312312312312#{dummy_data}", # gitleaks:allow
              offset: 1
            ),
            new_payload(id: 555, data: "data with no secret#{dummy_data}", offset: 1),
            new_payload(id: 666, data: "data with no secret#{dummy_data}", offset: 1),
            new_payload(
              id: 777,
              data: "#{dummy_data}\nglptt-1231231231231231231212312312312312312312", # gitleaks:allow
              offset: 1
            )
          ]
        end

        it "matches multiple rules" do
          expect(scan.secrets_scan(payloads, subprocess: true)).to eq(expected_response)
        end

        it "allocates less memory than when running in main process" do
          forked_stats = Benchmark::Malloc.new.run { scan.secrets_scan(large_payloads, subprocess: true) }
          non_forked_stats = Benchmark::Malloc.new.run { scan.secrets_scan(large_payloads, subprocess: false) }

          max_processes = Gitlab::SecretDetection::Scan::MAX_PROCS_PER_REQUEST

          forked_memory = forked_stats.allocated.total_memory
          non_forked_memory = non_forked_stats.allocated.total_memory
          forked_obj_allocs = forked_stats.allocated.total_objects
          non_forked_obj_allocs = non_forked_stats.allocated.total_objects

          expect(non_forked_memory).to be >= forked_memory * max_processes
          expect(non_forked_obj_allocs).to be >= forked_obj_allocs * max_processes
        end
      end
    end

    context "when configured with time out" do
      let(:each_payload_timeout_secs) { 0.000_001 } # 1 micro-sec to intentionally timeout large payload

      let(:large_data) do
        ("large data with a secret glpat-12312312312312312312\n" * 10_000_000).freeze # gitleaks:allow
      end

      let(:payloads) do
        [
          new_payload(id: 111, data: "GR134894112312312312312312312", offset: 1), # gitleaks:allow
          new_payload(id: 333, data: "data with no secret", offset: 1),
          new_payload(id: 333, data: large_data, offset: 1)
        ]
      end

      let(:all_large_payloads) do
        [
          new_payload(id: 111, data: large_data, offset: 1),
          new_payload(id: 222, data: large_data, offset: 1),
          new_payload(id: 333, data: large_data, offset: 1)
        ]
      end

      it "whole secret detection scan operation times out" do
        scan_timeout_secs = 0.000_001 # 1 micro-sec to intentionally timeout large payload

        expected_response = Gitlab::SecretDetection::Response.new(
          Gitlab::SecretDetection::Status::SCAN_TIMEOUT,
          nil,
          empty_applied_exclusions
        )

        begin
          response = scan.secrets_scan(payloads, timeout: scan_timeout_secs)
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

      it "one of the payloads times out while others continue to get scanned" do
        expected_response = Gitlab::SecretDetection::Response.new(
          Gitlab::SecretDetection::Status::FOUND_WITH_ERRORS,
          [
            Gitlab::SecretDetection::Finding.new(
              payloads[0][:id],
              Gitlab::SecretDetection::Status::FOUND,
              1,
              ruleset['rules'][2]['id'],
              ruleset['rules'][2]['description']
            ),
            Gitlab::SecretDetection::Finding.new(
              payloads[2][:id],
              Gitlab::SecretDetection::Status::PAYLOAD_TIMEOUT
            )
          ],
          empty_applied_exclusions
        )

        expect(scan.secrets_scan(payloads, payload_timeout: each_payload_timeout_secs)).to eq(expected_response)
      end

      it "all the payloads time out" do
        # scan status changes to SCAN_TIMEOUT when *all* the payloads time out
        expected_scan_status = Gitlab::SecretDetection::Status::SCAN_TIMEOUT

        expected_response = Gitlab::SecretDetection::Response.new(
          expected_scan_status,
          [
            Gitlab::SecretDetection::Finding.new(
              all_large_payloads[0][:id],
              Gitlab::SecretDetection::Status::PAYLOAD_TIMEOUT
            ),
            Gitlab::SecretDetection::Finding.new(
              all_large_payloads[1][:id],
              Gitlab::SecretDetection::Status::PAYLOAD_TIMEOUT
            ),
            Gitlab::SecretDetection::Finding.new(
              all_large_payloads[2][:id],
              Gitlab::SecretDetection::Status::PAYLOAD_TIMEOUT
            )
          ],
          empty_applied_exclusions
        )

        expect(scan.secrets_scan(all_large_payloads,
          payload_timeout: each_payload_timeout_secs)).to eq(expected_response)
      end
    end

    context "when using exclusions" do
      let(:payloads) do
        [
          new_payload(id: 111, data: "data with no secret", offset: 1),
          new_payload(id: 222, data: "GR134894145645645645645645645", offset: 1), # gitleaks:allow
          new_payload(id: 333, data: "GR134894145645645645645645789", offset: 1), # gitleaks:allow
          new_payload(id: 444, data: "GR134894112312312312312312312", offset: 1), # gitleaks:allow
          new_payload(id: 555, data: "glpat-12312312312312312312", offset: 1), # gitleaks:allow,
          new_payload(
            id: 666,
            data: "test data\nglptt-1231231231231231231212312312312312312312\nline contd", # gitleaks:allow
            offset: 1
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
            payloads[1].data,
            payloads[2].data,
            *payloads[5].data.lines
          ]
        end

        it "excludes values from being detected" do
          expected_scan_status = Gitlab::SecretDetection::Status::FOUND

          expected_response = Gitlab::SecretDetection::Response.new(
            expected_scan_status,
            [
              Gitlab::SecretDetection::Finding.new(
                payloads[1][:id],
                expected_scan_status,
                1,
                ruleset['rules'][2]['id'],
                ruleset['rules'][2]['description']
              ),
              Gitlab::SecretDetection::Finding.new(
                payloads[2][:id],
                expected_scan_status,
                1,
                ruleset['rules'][2]['id'],
                ruleset['rules'][2]['description']
              ),
              Gitlab::SecretDetection::Finding.new(
                payloads[5][:id],
                expected_scan_status,
                2,
                ruleset['rules'][1]['id'],
                ruleset['rules'][1]['description']
              )
            ],
            exclusions[:raw_value]
          )

          expect(scan.secrets_scan(payloads, exclusions:)).to eq(expected_response)
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
                payloads[5][:id],
                expected_scan_status,
                2,
                ruleset['rules'][1]['id'],
                ruleset['rules'][1]['description']
              )
            ],
            [
              exclusion.new(value: "gitlab_runner_registration_token"),
              exclusion.new(value: "gitlab_runner_registration_token"),
              exclusion.new(value: "gitlab_runner_registration_token"),
              exclusion.new(value: "gitlab_personal_access_token")
            ]
          )

          expect(scan.secrets_scan(payloads, exclusions:)).to eq(expected_response)
        end
      end
    end
  end
end
