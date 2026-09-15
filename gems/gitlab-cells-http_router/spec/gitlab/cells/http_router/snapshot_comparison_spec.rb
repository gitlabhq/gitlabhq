# frozen_string_literal: true

RSpec.describe Gitlab::Cells::HttpRouter::SnapshotComparison do
  # A snapshot has to clear MIN_ROUTES to be accepted, so build the bulk of it
  # from filler and append the templates a given example actually cares about.
  def payload(*templates, filler: described_class::MIN_ROUTES, pretty: true)
    routes = Array.new(filler) { |i| { "template" => "/filler/#{i}", "example" => "/filler/#{i}" } }
    routes += templates.map { |template| { "template" => template, "example" => template } }

    pretty ? "#{JSON.pretty_generate(routes)}\n" : JSON.generate(routes)
  end

  describe "#identical?" do
    it "is true for byte-identical payloads" do
      snapshot = payload("/a")

      comparison = described_class.new(gitlab_payload: snapshot, router_payload: snapshot)

      expect(comparison).to be_identical
      expect(comparison).not_to be_formatting_only
      expect(comparison.gitlab_only).to be_empty
      expect(comparison.router_only).to be_empty
    end

    it "is false when only the serialization differs" do
      comparison = described_class.new(
        gitlab_payload: payload("/a", pretty: true),
        router_payload: payload("/a", pretty: false)
      )

      expect(comparison).not_to be_identical
    end
  end

  describe "#formatting_only?" do
    it "is true when the templates match but the bytes do not" do
      comparison = described_class.new(
        gitlab_payload: payload("/a", pretty: true),
        router_payload: payload("/a", pretty: false)
      )

      expect(comparison).to be_formatting_only
      expect(comparison.gitlab_only).to be_empty
      expect(comparison.router_only).to be_empty
    end

    it "is false when a template differs" do
      comparison = described_class.new(
        gitlab_payload: payload("/a"),
        router_payload: payload("/b")
      )

      expect(comparison).not_to be_formatting_only
    end
  end

  describe "template sets" do
    subject(:comparison) do
      described_class.new(
        gitlab_payload: payload("/only-gitlab", "/shared"),
        router_payload: payload("/shared", "/only-router")
      )
    end

    it "reports each side's exclusive templates, sorted" do
      expect(comparison.gitlab_only).to eq(["/only-gitlab"])
      expect(comparison.router_only).to eq(["/only-router"])
    end

    it "sorts multiple templates" do
      result = described_class.new(
        gitlab_payload: payload("/z", "/a", "/m"),
        router_payload: payload
      )

      expect(result.gitlab_only).to eq(%w[/a /m /z])
    end
  end

  describe "invalid payloads" do
    it "rejects a non-JSON body, naming the side it came from" do
      expect { described_class.new(gitlab_payload: payload("/a"), router_payload: "<!DOCTYPE html>") }
        .to raise_error(described_class::InvalidSnapshotError, /HTTP Router snapshot is not valid JSON/)
    end

    it "rejects a JSON object" do
      expect { described_class.new(gitlab_payload: payload("/a"), router_payload: '{"routes":[]}') }
        .to raise_error(described_class::InvalidSnapshotError, /expected an array of routes/)
    end

    it "rejects a truncated array" do
      expect { described_class.new(gitlab_payload: payload("/a"), router_payload: payload(filler: 10)) }
        .to raise_error(described_class::InvalidSnapshotError, /holds only 10 routes/)
    end

    it "rejects an entry without a template" do
      routes = Array.new(described_class::MIN_ROUTES) { { "example" => "/x" } }

      expect { described_class.new(gitlab_payload: payload("/a"), router_payload: JSON.generate(routes)) }
        .to raise_error(described_class::InvalidSnapshotError, /entry without a template/)
    end

    it "names the GitLab side when that is the invalid one" do
      expect { described_class.new(gitlab_payload: "[]", router_payload: payload("/a")) }
        .to raise_error(described_class::InvalidSnapshotError, /GitLab snapshot holds only 0 routes/)
    end

    it "exposes the side that failed, so a caller can tell a bad download from a bad local file" do
      expect { described_class.new(gitlab_payload: payload("/a"), router_payload: "<!DOCTYPE html>") }
        .to raise_error(described_class::InvalidSnapshotError) { |error| expect(error.source).to eq(:router) }

      expect { described_class.new(gitlab_payload: "[]", router_payload: payload("/a")) }
        .to raise_error(described_class::InvalidSnapshotError) { |error| expect(error.source).to eq(:gitlab) }
    end
  end

  describe "with the real snapshot shape" do
    it "ignores the extra per-route fields when comparing templates" do
      base = Array.new(described_class::MIN_ROUTES) do |i|
        { "template" => "/r/#{i}", "example" => "/r/#{i}" }
      end
      enriched = base.map do |route|
        route.merge("acceptsFormat" => true, "dottedExample" => "#{route['example']}.foo")
      end

      comparison = described_class.new(
        gitlab_payload: JSON.generate(base),
        router_payload: JSON.generate(enriched)
      )

      expect(comparison).not_to be_identical
      expect(comparison).to be_formatting_only
    end
  end
end
