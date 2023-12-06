# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SecretDetection::Scan, feature_category: :secret_detection do
  subject(:scan) { described_class.new }

  def new_blob(id:, data:)
    Struct.new(:id, :data).new(id, data)
  end

  let(:ruleset) do
    {
      "title" => "gitleaks config",
      "rules" => [
        { "id" => "gitlab_personal_access_token",
          "description" => "GitLab Personal Access Token",
          "regex" => "glpat-[0-9a-zA-Z_\\-]{20}",
          "tags" => %w[gitlab revocation_type],
          "keywords" => ["glpat"] },
        { "id" => "gitlab_pipeline_trigger_token",
          "description" => "GitLab Pipeline Trigger Token",
          "regex" => "glptt-[0-9a-zA-Z_\\-]{20}",
          "tags" => ["gitlab"],
          "keywords" => ["glptt"] },
        { "id" => "gitlab_runner_registration_token",
          "description" => "GitLab Runner Registration Token",
          "regex" => "GR1348941[0-9a-zA-Z_-]{20}",
          "tags" => ["gitlab"],
          "keywords" => ["GR1348941"] },
        { "id" => "gitlab_feed_token",
          "description" => "GitLab Feed Token",
          "regex" => "glft-[0-9a-zA-Z_-]{20}",
          "tags" => ["gitlab"],
          "keywords" => ["glft"] }
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

    context 'when the blob does not contain a secret' do
      let(:blobs) do
        [
          new_blob(id: 1234, data: "no secrets")
        ]
      end

      it "does not match" do
        expected_response = Gitlab::SecretDetection::Response.new(Gitlab::SecretDetection::Status::NOT_FOUND)
        expect(scan.secrets_scan(blobs)).to eq(expected_response)
      end

      it "attempts to keyword match returning no blobs for further scan" do
        expect(scan).to receive(:filter_by_keywords).with(blobs).and_return([])
        scan.secrets_scan(blobs)
      end

      it "does not attempt to regex match" do
        expect(scan).not_to receive(:match_rules_bulk)
        scan.secrets_scan(blobs)
      end
    end

    context "when multiple blobs contains secrets" do
      let(:blobs) do
        [
          new_blob(id: 111, data: "glpat-12312312312312312312"), # gitleaks:allow
          new_blob(id: 222, data: "\n\nglptt-12312312312312312312"), # gitleaks:allow
          new_blob(id: 333, data: "data with no secret"),
          new_blob(id: 444, data: "GR134894112312312312312312312\nglft-12312312312312312312") # gitleaks:allow
        ]
      end

      it "matches glpat" do
        expected_response = Gitlab::SecretDetection::Response.new(
          Gitlab::SecretDetection::Status::FOUND,
          [
            Gitlab::SecretDetection::Finding.new(
              blobs[0].id,
              Gitlab::SecretDetection::Status::FOUND,
              1,
              ruleset['rules'][0]['id'],
              ruleset['rules'][0]['description']
            ),
            Gitlab::SecretDetection::Finding.new(
              blobs[1].id,
              Gitlab::SecretDetection::Status::FOUND,
              3,
              ruleset['rules'][1]['id'],
              ruleset['rules'][1]['description']
            ),
            Gitlab::SecretDetection::Finding.new(
              blobs[3].id,
              Gitlab::SecretDetection::Status::FOUND,
              1,
              ruleset['rules'][2]['id'],
              ruleset['rules'][2]['description']
            ),
            Gitlab::SecretDetection::Finding.new(
              blobs[3].id,
              Gitlab::SecretDetection::Status::FOUND,
              2,
              ruleset['rules'][3]['id'],
              ruleset['rules'][3]['description']
            )
          ]
        )

        expect(scan.secrets_scan(blobs)).to eq(expected_response)
      end
    end

    context "when configured with time out" do
      let(:large_data) do
        ("large data with a secret glpat-12312312312312312312\n" * 10_000_000).freeze # gitleaks:allow
      end

      let(:blobs) do
        [
          new_blob(id: 111, data: "GR134894112312312312312312312"), # gitleaks:allow
          new_blob(id: 333, data: "data with no secret"),
          new_blob(id: 333, data: large_data)
        ]
      end

      it "whole secret detection scan operation times out" do
        scan_timeout_secs = 0.000_001 # 1 micro-sec to intentionally timeout large blob
        response = Gitlab::SecretDetection::Response.new(Gitlab::SecretDetection::Status::SCAN_TIMEOUT)
        expect(scan.secrets_scan(blobs, timeout: scan_timeout_secs)).to eq(response)
      end

      it "one of the blobs times out while others continue to get scanned" do
        each_blob_timeout_secs = 0.000_001 # 1 micro-sec to intentionally timeout large blob

        expected_response = Gitlab::SecretDetection::Response.new(
          Gitlab::SecretDetection::Status::FOUND_WITH_ERRORS,
          [
            Gitlab::SecretDetection::Finding.new(
              blobs[0].id, Gitlab::SecretDetection::Status::FOUND, 1,
              ruleset['rules'][2]['id'],
              ruleset['rules'][2]['description']
            ),
            Gitlab::SecretDetection::Finding.new(
              blobs[2].id, Gitlab::SecretDetection::Status::BLOB_TIMEOUT
            )
          ])

        expect(scan.secrets_scan(blobs, blob_timeout: each_blob_timeout_secs)).to eq(expected_response)
      end

      it "all the blobs time out" do
        each_blob_timeout_secs = 0.000_001 # 1 micro-sec to intentionally timeout large blob

        all_large_blobs = [
          new_blob(id: 111, data: large_data),
          new_blob(id: 222, data: large_data),
          new_blob(id: 333, data: large_data)
        ]

        # scan status changes to SCAN_TIMEOUT when *all* the blobs time out
        expected_scan_status = Gitlab::SecretDetection::Status::SCAN_TIMEOUT

        expected_response = Gitlab::SecretDetection::Response.new(
          expected_scan_status,
          [
            Gitlab::SecretDetection::Finding.new(
              all_large_blobs[0].id, Gitlab::SecretDetection::Status::BLOB_TIMEOUT
            ),
            Gitlab::SecretDetection::Finding.new(
              all_large_blobs[1].id, Gitlab::SecretDetection::Status::BLOB_TIMEOUT
            ),
            Gitlab::SecretDetection::Finding.new(
              all_large_blobs[2].id, Gitlab::SecretDetection::Status::BLOB_TIMEOUT
            )
          ])

        expect(scan.secrets_scan(all_large_blobs, blob_timeout: each_blob_timeout_secs)).to eq(expected_response)
      end
    end
  end
end
