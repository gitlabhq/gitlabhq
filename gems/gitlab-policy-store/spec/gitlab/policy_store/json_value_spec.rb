# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::PolicyStore::JsonValue do
  describe ".deep_stringify" do
    it "stringifies keys at every depth" do
      expect(described_class.deep_stringify({ groups: { including: [{ id: 10 }] } }))
        .to eq({ "groups" => { "including" => [{ "id" => 10 }] } })
    end

    it "stringifies symbol values" do
      expect(described_class.deep_stringify({ match_mode: :any })).to eq({ "match_mode" => "any" })
    end

    it "leaves other scalars as they are" do
      expect(described_class.deep_stringify({ id: 5, applies: true, name: nil }))
        .to eq({ "id" => 5, "applies" => true, "name" => nil })
    end

    it "walks an array at the top level" do
      expect(described_class.deep_stringify([{ type: :scan_finding }])).to eq([{ "type" => "scan_finding" }])
    end

    it "returns a plain Hash, whatever hash subclass it was given" do
      indifferent = Class.new(Hash).new.merge({ "match_mode" => "any" })

      expect(described_class.deep_stringify(indifferent).class).to eq(Hash)
    end

    it "passes through a value that is neither a collection nor a symbol" do
      expect(described_class.deep_stringify("package gitlab.scope")).to eq("package gitlab.scope")
    end

    it "is idempotent, since the repository and the transpiler both stringify policy_scope" do
      mixed = {
        compliance_frameworks: [{ id: 5 }],
        match_mode: :any,
        "projects" => { excluding: [{ type: :personal }, 7] }
      }

      stringified = described_class.deep_stringify(mixed)

      expect(described_class.deep_stringify(stringified)).to eq(stringified)
    end
  end
end
