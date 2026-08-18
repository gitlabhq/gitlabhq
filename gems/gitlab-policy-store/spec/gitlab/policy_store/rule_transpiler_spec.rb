# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::PolicyStore::RuleTranspiler do
  def fixture_rego(name)
    File.read(File.expand_path("../../fixtures/rules/#{name}/rule.rego", __dir__))
  end

  def transpile(rule, rule_index: 0)
    described_class.new(rule, rule_index: rule_index).transpile
  end

  describe "#transpile" do
    context "with golden fixtures" do
      it "regenerates environment_names byte-for-byte" do
        rego = transpile({ type: "environment", value: { names: %w[production staging] } })

        expect(rego).to eq(fixture_rego("environment_names"))
      end

      it "regenerates environment_names_and_tiers byte-for-byte" do
        rego = transpile({ type: "environment", value: { names: ["prod-us-east"], tiers: ["production"] } })

        expect(rego).to eq(fixture_rego("environment_names_and_tiers"))
      end
    end

    context "with a custom rule" do
      let(:authored_program) { "package governance\n\nviolation contains {\"msg\": \"no\"}\n" }

      it "returns the authored program unchanged" do
        expect(transpile({ type: "custom", value: authored_program })).to eq(authored_program)
      end

      it "does not prepend a second package declaration" do
        expect(transpile({ type: "custom", value: authored_program }).scan("package").length).to eq(1)
      end

      it "reads the package declaration past leading comments and blank lines" do
        commented = "# authored by hand\n\npackage governance\n\nallow := true\n"

        expect(transpile({ type: "custom", value: commented })).to eq(commented)
      end

      it "reads the package declaration past a trailing comment" do
        annotated = "package governance # deployment freeze\n\nallow := true\n"

        expect(transpile({ type: "custom", value: annotated })).to eq(annotated)
      end

      it "reads the package declaration with no space before the comment" do
        annotated = "package governance#freeze\n\nallow := true\n"

        expect(transpile({ type: "custom", value: annotated })).to eq(annotated)
      end
    end

    context "with an environment rule" do
      it "emits a tier condition on its own when no names are authored", :aggregate_failures do
        rego = transpile({ type: "environment", value: { tiers: %w[production] } })

        expect(rego).to include("input.environment.tier in {\"production\"}")
        expect(rego).not_to include("input.environment.name in")
      end

      it "requires both conditions to hold when names and tiers are authored" do
        rego = transpile({ type: "environment", value: { names: ["production"], tiers: ["production"] } })

        expect(rego.scan("violation contains").length).to eq(1)
      end

      it "escapes authored names, which reach the generated program as source" do
        rego = transpile({ type: "environment", value: { names: [%(a "quoted"\nname)] } })

        expect(rego).to include('{"a \"quoted\"\nname"}')
      end

      it "carries the rule index in the violation, which a merged module needs to tell rules apart" do
        rego = transpile({ type: "environment", value: { tiers: ["production"] } }, rule_index: 2)

        expect(rego).to include('"rule_index": 2')
      end
    end

    context "with input coercion" do
      it "treats string and symbol keys identically (jsonb round-trips as strings)" do
        with_symbols = transpile({ type: "environment", value: { names: ["production"] } })
        with_strings = transpile({ "type" => "environment", "value" => { "names" => ["production"] } })

        expect(with_strings).to eq(with_symbols)
      end

      it "deduplicates and sorts names, so authoring order does not change the stored text" do
        rego = transpile({ type: "environment", value: { names: %w[staging production staging] } })

        expect(rego).to include('input.environment.name in {"production", "staging"}')
      end

      it "drops entries that are not usable strings" do
        rego = transpile({ type: "environment", value: { names: [42, "", "  ", nil, "production"] } })

        expect(rego).to include('input.environment.name in {"production"}')
      end
    end

    context "with a rule it cannot compile" do
      def expect_invalid(rule, message, rule_index: 3)
        expect { transpile(rule, rule_index: rule_index) }
          .to raise_error(Gitlab::PolicyStore::ValidationError, "rule #{rule_index}: #{message}")
      end

      it "rejects a rule type it has no emitter for" do
        expect_invalid({ type: "scan_finding", value: {} }, 'unsupported rule type "scan_finding"')
      end

      it "rejects a missing rule type" do
        expect_invalid({ value: {} }, "unsupported rule type nil")
      end

      it "rejects anything that is not an object" do
        expect_invalid("package governance", "expected an object with a type")
      end

      it "rejects a custom rule carrying no source" do
        expect_invalid({ type: "custom", value: "  " }, "custom rule requires Rego source in value")
      end

      it "rejects a custom rule whose value is structured configuration" do
        expect_invalid({ type: "custom", value: { names: ["production"] } },
          "custom rule requires Rego source in value")
      end

      it "rejects a custom rule declaring another package" do
        expect_invalid({ type: "custom", value: "package gitlab.policy\n\nallow := true\n" },
          'custom rule must declare `package governance`, found "gitlab.policy"')
      end

      it "rejects a custom rule declaring a subpackage of governance" do
        expect_invalid({ type: "custom", value: "package governance.deploy\n\nallow := true\n" },
          'custom rule must declare `package governance`, found "governance.deploy"')
      end

      it "rejects a subpackage whose declaration carries a trailing comment" do
        expect_invalid({ type: "custom", value: "package governance.deploy # still wrong\n\nallow := true\n" },
          'custom rule must declare `package governance`, found "governance.deploy"')
      end

      it "rejects a custom rule with no package declaration" do
        expect_invalid({ type: "custom", value: "allow := true\n" },
          "custom rule must declare `package governance`, found nil")
      end

      it "rejects a name whose bytes are not valid UTF-8" do
        expect_invalid({ type: "environment", value: { names: ["prod\xFF"] } },
          "environment rule requires at least one of names or tiers")
      end

      it "rejects an environment rule with neither names nor tiers" do
        expect_invalid({ type: "environment", value: {} },
          "environment rule requires at least one of names or tiers")
      end

      it "rejects an environment rule whose names are all unusable" do
        expect_invalid({ type: "environment", value: { names: [""], tiers: [] } },
          "environment rule requires at least one of names or tiers")
      end

      it "rejects an environment rule whose value is not an object" do
        expect_invalid({ type: "environment", value: "production" },
          "environment rule requires at least one of names or tiers")
      end

      # `calendar` is advertised by the catalogue ahead of its emitter, so this pins which
      # types are still pending rather than that none are. Adding the emitter fails it.
      it "emits for the catalogued rule types it supports, and names the ones it does not yet",
        :aggregate_failures do
        refusal_for_an_empty_rule = {
          "custom" => "custom rule requires Rego source in value",
          "environment" => "environment rule requires at least one of names or tiers"
        }

        catalogued = Gitlab::PolicyStore::Rules::ALL.map { |rule| rule[:id] }

        expect(catalogued).to include(*refusal_for_an_empty_rule.keys)
        expect(catalogued - refusal_for_an_empty_rule.keys).to contain_exactly("calendar")
        expect_invalid({ type: "calendar" }, 'unsupported rule type "calendar"', rule_index: 0)

        refusal_for_an_empty_rule.each do |rule_type, message|
          expect_invalid({ type: rule_type }, message, rule_index: 0)
        end
      end
    end

    context "with text the emitted program could not carry" do
      it "refuses a name whose bytes cannot reach UTF-8, rather than raising from the encoder" do
        expect { transpile({ type: "environment", value: { names: ["prod\xFF".b] } }) }
          .to raise_error(Gitlab::PolicyStore::ValidationError,
            'rule 0: value cannot be encoded as UTF-8: "prod\xFF"')
      end

      it "refuses a custom program that is not UTF-8, which the package scan cannot even read" do
        expect { transpile({ type: "custom", value: "package governance\n".encode("UTF-16LE") }) }
          .to raise_error(Gitlab::PolicyStore::ValidationError,
            "rule 0: custom rule source must be UTF-8, found UTF-16LE")
      end

      it "refuses a custom program in a dummy encoding, which cannot even be stripped" do
        expect { transpile({ type: "custom", value: "package governance\n".encode("UTF-16") }) }
          .to raise_error(Gitlab::PolicyStore::ValidationError,
            "rule 0: custom rule source must be UTF-8, found UTF-16")
      end

      it "refuses a name in a dummy encoding rather than raising from the strip" do
        expect { transpile({ type: "environment", value: { names: ["production".encode("UTF-16")] } }) }
          .to raise_error(Gitlab::PolicyStore::ValidationError,
            "rule 0: environment rule requires at least one of names or tiers")
      end

      it "accepts an ASCII-only program whatever encoding it is tagged with, since it reaches UTF-8" do
        program = "package governance\n\nallow := true\n"

        expect(transpile({ type: "custom", value: program.b })).to eq(program)
      end

      it "accepts a name that transcodes cleanly" do
        rego = transpile({ type: "environment", value: { names: ["production".encode("UTF-16LE")] } })

        expect(rego).to include('input.environment.name in {"production"}')
      end
    end

    context "with a value too large to echo back" do
      it "names an unsupported type by its length rather than repeating it" do
        expect { transpile({ type: "z" * 200 }) }
          .to raise_error(Gitlab::PolicyStore::ValidationError,
            "rule 0: unsupported rule type #{('z' * 64).inspect} (200 characters)")
      end

      it "names a value that is not a string by its type, since rendering one can be superlinear" do
        expect { transpile({ type: 10**5_000_000 }) }
          .to raise_error(Gitlab::PolicyStore::ValidationError, "rule 0: unsupported rule type Integer")
      end
    end

    context "with a rule index a caller supplied" do
      it "coerces it, so it cannot carry Rego into the emitted program", :aggregate_failures do
        rego = transpile({ type: "environment", value: { tiers: ["production"] } },
          rule_index: "0\n\nviolation contains {\"msg\": \"injected\"} if { true }\n\n# ")

        expect(rego).to include("# rule 0: environment")
        expect(rego).not_to include("injected")
      end
    end
  end
end
