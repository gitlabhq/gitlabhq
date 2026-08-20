# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::PolicyStore::RuleProgramMerger do
  def fixture_rego(name)
    File.read(File.expand_path("../../fixtures/policies/#{name}/policy.rego", __dir__))
  end

  def compiled_rule(type, value, rule_index:)
    { "type" => type, "value" => value,
      "rego" => Gitlab::PolicyStore::RuleTranspiler.new({ "type" => type, "value" => value },
        rule_index: rule_index).transpile }
  end

  def merge(rules)
    described_class.new(rules).merge
  end

  describe "#merge" do
    context "with golden fixtures" do
      it "regenerates one_rule byte-for-byte" do
        rules = [compiled_rule("environment", { "tiers" => ["production"] }, rule_index: 0)]

        expect(merge(rules)).to eq(fixture_rego("one_rule"))
      end

      it "regenerates two_environment_rules byte-for-byte, in authored order" do
        rules = [
          compiled_rule("environment", { "names" => ["prod-us-east"] }, rule_index: 0),
          compiled_rule("environment", { "tiers" => ["production"] }, rule_index: 1)
        ]

        expect(merge(rules)).to eq(fixture_rego("two_environment_rules"))
      end

      it "regenerates environment_and_custom byte-for-byte" do
        custom_program = "package governance\n\nviolation contains {\"msg\": \"no production deploys\"}\n"
        rules = [
          compiled_rule("environment", { "tiers" => ["production"] }, rule_index: 0),
          { "type" => "custom", "value" => custom_program, "rego" => custom_program }
        ]

        expect(merge(rules)).to eq(fixture_rego("environment_and_custom"))
      end
    end

    context "with no rules" do
      it "returns nil rather than an empty module" do
        expect(merge([])).to be_nil
      end
    end

    context "with the package declaration" do
      it "keeps only one, however many rules are merged" do
        rules = [
          compiled_rule("environment", { "tiers" => ["production"] }, rule_index: 0),
          compiled_rule("environment", { "names" => ["prod-us-east"] }, rule_index: 1)
        ]

        expect(merge(rules).scan("package governance").length).to eq(1)
      end
    end

    context "with each rule's header" do
      it "preserves the rule N header from every merged program", :aggregate_failures do
        rules = [
          compiled_rule("environment", { "tiers" => ["production"] }, rule_index: 0),
          compiled_rule("environment", { "names" => ["prod-us-east"] }, rule_index: 1)
        ]

        merged = merge(rules)

        expect(merged).to include("# rule 0: environment")
        expect(merged).to include("# rule 1: environment")
      end
    end

    context "when called twice with the same rules" do
      it "produces identical bytes" do
        rules = [compiled_rule("environment", { "tiers" => ["production"] }, rule_index: 0)]

        first_pass = merge(rules)
        second_pass = merge(rules)

        expect(first_pass).to eq(second_pass)
      end
    end

    context "with a bare custom rule whose program is only the package line" do
      it "does not add a second trailing newline after an empty stripped body" do
        rule = { "type" => "custom", "value" => "package governance", "rego" => "package governance" }

        expect(merge([rule])).to eq("package governance\n")
      end
    end

    context "with custom rules authored without a trailing newline" do
      it "keeps them on separate lines rather than fusing them into one" do
        first_program = "package governance\nviolation contains {\"msg\": \"a\"}"
        second_program = "package governance\nviolation contains {\"msg\": \"b\"}"
        rules = [
          { "type" => "custom", "value" => first_program, "rego" => first_program },
          { "type" => "custom", "value" => second_program, "rego" => second_program }
        ]

        expect(merge(rules))
          .to eq("package governance\nviolation contains {\"msg\": \"a\"}\nviolation contains {\"msg\": \"b\"}\n")
      end
    end

    context "with a rule that carries no compiled rego" do
      it "raises rather than silently omitting the rule from the merged module" do
        rules = [compiled_rule("environment", { "tiers" => ["production"] }, rule_index: 0), { "type" => "custom" }]

        expect { merge(rules) }
          .to raise_error(Gitlab::PolicyStore::Error, "rule 1 has no compiled rego to merge")
      end
    end

    context "with a rule whose compiled rego is an empty string rather than absent" do
      it "raises the same as a missing rego, rather than silently vanishing from the merged module" do
        rules = [
          compiled_rule("environment", { "tiers" => ["production"] }, rule_index: 0),
          { "type" => "custom", "rego" => "" }
        ]

        expect { merge(rules) }
          .to raise_error(Gitlab::PolicyStore::Error, "rule 1 has no compiled rego to merge")
      end
    end

    context "with a rule whose compiled rego is not a String" do
      [false, true, { "not" => "a string" }, 42].each do |malformed_rego|
        it "raises rather than raising NoMethodError for a #{malformed_rego.class}" do
          rules = [{ "type" => "custom", "rego" => malformed_rego }]

          expect { merge(rules) }
            .to raise_error(Gitlab::PolicyStore::Error, "rule 0 has no compiled rego to merge")
        end
      end
    end

    context "with a rule that is not a Hash" do
      [nil, 42, true, ["nested"], "a string"].each do |malformed_rule|
        it "raises rather than raising NoMethodError or TypeError for a #{malformed_rule.class}" do
          expect { merge([malformed_rule]) }
            .to raise_error(Gitlab::PolicyStore::Error, "rule 0 has no compiled rego to merge")
        end
      end
    end

    context "when rules itself is not an Array" do
      [nil, "not an array", 42, { "type" => "custom" }].each do |malformed_rules|
        it "raises rather than raising NoMethodError for a #{malformed_rules.class}" do
          expect { merge(malformed_rules) }
            .to raise_error(Gitlab::PolicyStore::Error, "rules must be an array of compiled entries")
        end
      end
    end
  end
end
