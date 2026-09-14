# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::PolicyStore::RuleProgramMerger do
  subject(:merged) { described_class.new(rules).merge }

  def fixture_rego(name)
    File.read(File.expand_path("../../fixtures/policies/#{name}/policy.rego", __dir__))
  end

  def compiled_rule(type, value, rule_index:)
    { "type" => type, "value" => value,
      "rego" => Gitlab::PolicyStore::RuleTranspiler.new({ "type" => type, "value" => value },
        rule_index: rule_index).transpile }
  end

  describe "#merge" do
    context "with golden fixtures" do
      context "with one rule" do
        let(:rules) { [compiled_rule("environment", { "tiers" => ["production"] }, rule_index: 0)] }

        it "regenerates one_rule byte-for-byte" do
          expect(merged).to eq(fixture_rego("one_rule"))
        end
      end

      context "with two environment rules" do
        let(:rules) do
          [
            compiled_rule("environment", { "names" => ["prod-us-east"] }, rule_index: 0),
            compiled_rule("environment", { "tiers" => ["production"] }, rule_index: 1)
          ]
        end

        it "regenerates two_environment_rules byte-for-byte, in authored order" do
          expect(merged).to eq(fixture_rego("two_environment_rules"))
        end
      end

      context "with an environment rule and a custom rule" do
        let(:rules) do
          custom_program = "package governance\n\nviolation contains {\"msg\": \"no production deploys\"}\n"
          [
            compiled_rule("environment", { "tiers" => ["production"] }, rule_index: 0),
            { "type" => "custom", "value" => custom_program, "rego" => custom_program }
          ]
        end

        it "regenerates environment_and_custom byte-for-byte" do
          expect(merged).to eq(fixture_rego("environment_and_custom"))
        end
      end
    end

    context "with no rules" do
      let(:rules) { [] }

      it "returns nil rather than an empty module" do
        expect(merged).to be_nil
      end
    end

    context "with the package declaration" do
      let(:rules) do
        [
          compiled_rule("environment", { "tiers" => ["production"] }, rule_index: 0),
          compiled_rule("environment", { "names" => ["prod-us-east"] }, rule_index: 1)
        ]
      end

      it "keeps only one, however many rules are merged" do
        expect(merged.scan("package governance").length).to eq(1)
      end
    end

    context "with each rule's header" do
      let(:rules) do
        [
          compiled_rule("environment", { "tiers" => ["production"] }, rule_index: 0),
          compiled_rule("environment", { "names" => ["prod-us-east"] }, rule_index: 1)
        ]
      end

      it "preserves the rule N header from every merged program", :aggregate_failures do
        expect(merged).to include("# rule 0: environment")
        expect(merged).to include("# rule 1: environment")
      end
    end

    context "when called twice with the same rules" do
      let(:rules) { [compiled_rule("environment", { "tiers" => ["production"] }, rule_index: 0)] }

      it "produces identical bytes" do
        first_pass = described_class.new(rules).merge
        second_pass = described_class.new(rules).merge

        expect(first_pass).to eq(second_pass)
      end
    end

    context "with a bare custom rule whose program is only the package line" do
      let(:rules) { [{ "type" => "custom", "value" => "package governance", "rego" => "package governance" }] }

      it "does not add a second trailing newline after an empty stripped body" do
        expect(merged).to eq("package governance\n")
      end
    end

    context "with custom rules authored without a trailing newline" do
      let(:rules) do
        first_program = "package governance\nviolation contains {\"msg\": \"a\"}"
        second_program = "package governance\nviolation contains {\"msg\": \"b\"}"
        [
          { "type" => "custom", "value" => first_program, "rego" => first_program },
          { "type" => "custom", "value" => second_program, "rego" => second_program }
        ]
      end

      it "keeps them on separate lines rather than fusing them into one" do
        expect(merged)
          .to eq("package governance\nviolation contains {\"msg\": \"a\"}\nviolation contains {\"msg\": \"b\"}\n")
      end
    end

    context "with a rule that carries no compiled rego" do
      let(:rules) do
        [compiled_rule("environment", { "tiers" => ["production"] }, rule_index: 0), { "type" => "custom" }]
      end

      it "raises rather than silently omitting the rule from the merged module" do
        expect { merged }
          .to raise_error(Gitlab::PolicyStore::Error, "rule 1 has no compiled rego to merge")
      end
    end

    context "with a rule whose compiled rego is an empty string rather than absent" do
      let(:rules) do
        [
          compiled_rule("environment", { "tiers" => ["production"] }, rule_index: 0),
          { "type" => "custom", "rego" => "" }
        ]
      end

      it "raises the same as a missing rego, rather than silently vanishing from the merged module" do
        expect { merged }
          .to raise_error(Gitlab::PolicyStore::Error, "rule 1 has no compiled rego to merge")
      end
    end

    context "with a rule whose compiled rego is not a String" do
      [false, true, { "not" => "a string" }, 42].each do |malformed_rego|
        context "with a #{malformed_rego.class}" do
          let(:rules) { [{ "type" => "custom", "rego" => malformed_rego }] }

          it "raises rather than raising NoMethodError" do
            expect { merged }
              .to raise_error(Gitlab::PolicyStore::Error, "rule 0 has no compiled rego to merge")
          end
        end
      end
    end

    context "with a rule that is not a Hash" do
      [nil, 42, true, ["nested"], "a string"].each do |malformed_rule|
        context "with a #{malformed_rule.class}" do
          let(:rules) { [malformed_rule] }

          it "raises rather than raising NoMethodError or TypeError" do
            expect { merged }
              .to raise_error(Gitlab::PolicyStore::Error, "rule 0 has no compiled rego to merge")
          end
        end
      end
    end

    context "when rules itself is not an Array" do
      [nil, "not an array", 42, { "type" => "custom" }].each do |malformed_rules|
        context "with a #{malformed_rules.class}" do
          let(:rules) { malformed_rules }

          it "raises rather than raising NoMethodError" do
            expect { merged }
              .to raise_error(Gitlab::PolicyStore::Error, "rules must be an array of compiled entries")
          end
        end
      end
    end
  end
end
