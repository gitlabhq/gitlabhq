# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::PolicyStore::RuleTranspiler do
  subject(:transpiler) { described_class.new(rule, rule_index: rule_index, max_projected_bytes: max_projected_bytes) }

  let(:rule_index) { 0 }
  let(:max_projected_bytes) { nil }

  def fixture_rego(name)
    File.read(File.expand_path("../../fixtures/rules/#{name}/rule.rego", __dir__))
  end

  def calendar_rule(**overrides)
    { type: "calendar",
      value: { windows: [{ name: "eoq",
                           tiers: ["production"],
                           starts_at: "2026-12-24T00:00:00Z",
                           ends_at: "2027-01-02T00:00:00Z" }.merge(overrides)] } }
  end

  describe "#transpile" do
    subject(:rego) { transpiler.transpile }

    context "with golden fixtures" do
      context "with an environment rule naming multiple names" do
        let(:rule) { { type: "environment", value: { names: %w[production staging] } } }

        it "regenerates environment_names byte-for-byte" do
          expect(rego).to eq(fixture_rego("environment_names"))
        end
      end

      context "with an environment rule naming a name and a tier" do
        let(:rule) { { type: "environment", value: { names: ["prod-us-east"], tiers: ["production"] } } }

        it "regenerates environment_names_and_tiers byte-for-byte" do
          expect(rego).to eq(fixture_rego("environment_names_and_tiers"))
        end
      end

      context "with a single calendar window" do
        let(:rule) do
          { type: "calendar",
            value: { windows: [{ name: "eoq-freeze",
                                 tiers: ["production"],
                                 starts_at: "2026-12-24T00:00:00Z",
                                 ends_at: "2027-01-02T00:00:00Z" }] } }
        end

        it "regenerates calendar_window byte-for-byte" do
          expect(rego).to eq(fixture_rego("calendar_window"))
        end
      end

      context "with two calendar windows authored with different UTC offsets" do
        let(:rule) do
          { type: "calendar",
            value: { windows: [{ name: "summit",
                                 tiers: %w[production staging],
                                 starts_at: "2026-09-01T12:00:00+02:00",
                                 ends_at: "2026-09-03T00:00:00Z" },
              { name: "eoq-freeze",
                tiers: ["production"],
                starts_at: "2026-12-24T00:00:00Z",
                ends_at: "2027-01-02T00:00:00Z" }] } }
        end

        let(:rule_index) { 2 }

        it "regenerates calendar_windows_with_offsets byte-for-byte" do
          expect(rego).to eq(fixture_rego("calendar_windows_with_offsets"))
        end
      end
    end

    context "with a custom rule" do
      let(:authored_program) { "package governance\n\nviolation contains {\"msg\": \"no\"}\n" }
      let(:rule) { { type: "custom", value: authored_program } }

      it "returns the authored program unchanged" do
        expect(rego).to eq(authored_program)
      end

      it "does not prepend a second package declaration" do
        expect(rego.scan("package").length).to eq(1)
      end

      context "when the package declaration follows leading comments and blank lines" do
        let(:authored_program) { "# authored by hand\n\npackage governance\n\nallow := true\n" }

        it "reads the package declaration past leading comments and blank lines" do
          expect(rego).to eq(authored_program)
        end
      end

      context "when the package declaration carries a trailing comment" do
        let(:authored_program) { "package governance # deployment freeze\n\nallow := true\n" }

        it "reads the package declaration past a trailing comment" do
          expect(rego).to eq(authored_program)
        end
      end

      context "when the trailing comment has no space before it" do
        let(:authored_program) { "package governance#freeze\n\nallow := true\n" }

        it "reads the package declaration with no space before the comment" do
          expect(rego).to eq(authored_program)
        end
      end
    end

    context "with an environment rule" do
      context "with only tiers authored" do
        let(:rule) { { type: "environment", value: { tiers: %w[production] } } }

        it "emits a tier condition on its own when no names are authored", :aggregate_failures do
          expect(rego).to include("input.environment.tier in {\"production\"}")
          expect(rego).not_to include("input.environment.name in")
        end
      end

      context "with both names and tiers authored" do
        let(:rule) { { type: "environment", value: { names: ["production"], tiers: ["production"] } } }

        it "requires both conditions to hold when names and tiers are authored" do
          expect(rego.scan("violation contains").length).to eq(1)
        end
      end

      context "with a name carrying a quote and a newline" do
        let(:rule) { { type: "environment", value: { names: [%(a "quoted"\nname)] } } }

        it "escapes authored names, which reach the generated program as source" do
          expect(rego).to include('{"a \"quoted\"\nname"}')
        end
      end

      # The engine counts a leading tab as 4 columns, so a raw bytesize understates the
      # width it measures; mirror that expansion when asserting no line crosses the cap.
      def engine_columns(line)
        line.chomp.sub(/\A\t+/) { |tabs| " " * (4 * tabs.length) }.bytesize
      end

      context "with a name set wide enough to exceed the engine's column cap" do
        let(:rule) do
          names = Array.new(60) { |index| format("environment-%04d", index) }
          { type: "environment", value: { names: names } }
        end

        it "spreads a set one member per line", :aggregate_failures do
          expect(rego).to include("input.environment.name in {\n\t\t\"environment-0000\",\n")
          expect(rego).to include("\t\t\"environment-0059\"\n\t}\n")
        end
      end

      it "keeps a set inline at the last width the engine accepts, and wraps one byte over",
        :aggregate_failures do
        inline = described_class.new({ type: "environment", value: { names: ["e" * 988] } }).transpile
        wrapped = described_class.new({ type: "environment", value: { names: ["e" * 989] } }).transpile

        expect(inline).to include(%(in {"#{'e' * 988}"}))
        expect(engine_columns(inline.lines.find { |line| line.include?("input.environment.name in") }))
          .to be < described_class::Emitters::Base::MAX_LINE_COLUMNS
        expect(wrapped).to include("in {\n")
      end

      context "with a tier set wide enough to exceed the engine's column cap" do
        let(:rule) do
          tiers = Array.new(60) { |index| format("production-region-%04d", index) }
          { type: "environment", value: { tiers: tiers } }
        end

        it "spreads a tier set the same way, since both conditions share the emitter" do
          expect(rego).to include("input.environment.tier in {\n")
        end
      end

      context "with a single member too long for even its own wrapped line" do
        let(:rule) { { type: "environment", value: { names: ["e" * 1013] } } }

        it "refuses it" do
          expect { rego }.to raise_error(Gitlab::PolicyStore::ValidationError, /too long for the engine's line limit/)
        end
      end

      context "with a rule index supplied" do
        let(:rule) { { type: "environment", value: { tiers: ["production"] } } }
        let(:rule_index) { 2 }

        it "carries the rule index in the violation, which a merged module needs to tell rules apart" do
          expect(rego).to include('"rule_index": 2')
        end
      end
    end

    context "with a calendar rule" do
      def windows_from(rego)
        rego[/freeze_window := \[\n(.*?)\n\t\]\[_\]/m, 1].lines.map(&:strip)
      end

      context "with an authored offset" do
        let(:rule) { calendar_rule(starts_at: "2026-09-01T12:00:00+02:00", ends_at: "2026-09-03T01:30:00-01:00") }

        it "normalizes it to UTC, so the emitted comparison holds", :aggregate_failures do
          expect(rego).to include('"starts_at": "2026-09-01T10:00:00Z"')
          expect(rego).to include('"ends_at": "2026-09-03T02:30:00Z"')
        end
      end

      context "with windows authored out of chronological order" do
        let(:rule) do
          { type: "calendar",
            value: { windows: [{ name: "second",
                                 tiers: ["production"],
                                 starts_at: "2027-01-01T00:00:00Z",
                                 ends_at: "2027-01-02T00:00:00Z" },
              { name: "first",
                tiers: ["production"],
                starts_at: "2026-01-01T00:00:00Z",
                ends_at: "2026-01-02T00:00:00Z" }] } }
        end

        it "keeps windows in the authored order" do
          expect(windows_from(rego)).to match([
            a_string_including('"name": "second"'),
            a_string_including('"name": "first"')
          ])
        end
      end

      context "with identical windows after normalization" do
        let(:rule) do
          { type: "calendar",
            value: { windows: [{ name: "eoq", tiers: ["production"], starts_at: "2026-12-24T00:00:00Z",
                                 ends_at: "2027-01-02T00:00:00Z" },
              { name: "eoq", tiers: ["production"], starts_at: "2026-12-24T00:00:00Z",
                ends_at: "2027-01-02T00:00:00Z" }] } }
        end

        it "de-duplicates them" do
          expect(windows_from(rego).length).to eq(1)
        end
      end

      context "with windows naming the same instant in different authored forms" do
        let(:rule) do
          { type: "calendar",
            value: { windows: [{ name: "eoq", tiers: ["production"], starts_at: "2026-09-01T12:00:00+02:00",
                                 ends_at: "2026-09-03T01:30:00-01:00" },
              { name: "eoq", tiers: ["production"], starts_at: "2026-09-01T10:00:00Z",
                ends_at: "2026-09-03T02:30:00Z" }] } }
        end

        it "de-duplicates them" do
          expect(windows_from(rego).length).to eq(1)
        end
      end

      context "with windows sharing a name but different tiers" do
        let(:rule) do
          { type: "calendar",
            value: { windows: [{ name: "eoq", tiers: ["production"], starts_at: "2026-12-24T00:00:00Z",
                                 ends_at: "2027-01-02T00:00:00Z" },
              { name: "eoq", tiers: ["staging"], starts_at: "2026-12-24T00:00:00Z",
                ends_at: "2027-01-02T00:00:00Z" }] } }
        end

        it "keeps them, since a name alone is not a duplicate" do
          expect(windows_from(rego).length).to eq(2)
        end
      end

      context "with a duplicate that is not adjacent in authored order" do
        let(:rule) do
          { type: "calendar",
            value: { windows: [{ name: "eoq", tiers: ["production"], starts_at: "2026-12-24T00:00:00Z",
                                 ends_at: "2027-01-02T00:00:00Z" },
              { name: "second", tiers: ["production"], starts_at: "2027-06-01T00:00:00Z",
                ends_at: "2027-06-02T00:00:00Z" },
              { name: "eoq", tiers: ["production"], starts_at: "2026-12-24T00:00:00Z",
                ends_at: "2027-01-02T00:00:00Z" }] } }
        end

        it "de-duplicates it all the same" do
          expect(windows_from(rego).length).to eq(2)
        end
      end

      context "with a bare calendar rule" do
        let(:rule) { calendar_rule }

        it "keeps the windows out of the package document, so two calendar rules can merge" do
          expect(rego).not_to match(/^\S+\s*:?=/)
        end

        it "binds the window without `some`, which a package-level rule of the same name would break",
          :aggregate_failures do
          expect(rego).to include("freeze_window := [")
          expect(rego).not_to include("some freeze_window")
        end

        it "does not check the byte budget when none is injected, the default for every other example here" do
          expect(rego).to include("freeze_window")
        end

        context "with a rule index supplied" do
          let(:rule_index) { 3 }

          it "carries the rule index in the violation, which a merged module needs to tell rules apart" do
            expect(rego).to include('"rule_index": 3')
          end
        end

        context "with a byte budget that rejects the raw window size" do
          let(:max_projected_bytes) { 10 }

          it "rejects windows whose raw size alone exceeds an injected byte budget" do
            expect { rego }
              .to raise_error(Gitlab::PolicyStore::ValidationError,
                /windows project to \d+ bytes, over the maximum of 10 bytes/)
          end
        end

        context "with a byte budget that accepts the raw window size" do
          let(:max_projected_bytes) { 1_000_000 }

          it "accepts windows whose raw size is within an injected byte budget" do
            expect(rego).to include("freeze_window")
          end
        end
      end

      context "with a window rejected on projected size before a malformed window would otherwise fail first" do
        let(:rule) { calendar_rule(starts_at: "not-a-timestamp") }
        let(:max_projected_bytes) { 10 }

        it "rejects on projected size" do
          expect { rego }
            .to raise_error(Gitlab::PolicyStore::ValidationError,
              /windows project to \d+ bytes, over the maximum of 10 bytes/)
        end
      end

      context "with windows whose projected size is exactly at the budget" do
        it "accepts at the budget and rejects one byte over", :aggregate_failures do
          at_budget = JSON.generate({ "name" => "eoq", "tiers" => ["production"],
                                       "starts_at" => "2026-12-24T00:00:00Z", "ends_at" => "2027-01-02T00:00:00Z" })
            .bytesize

          expect(described_class.new(calendar_rule, max_projected_bytes: at_budget).transpile)
            .to include("freeze_window")
          expect { described_class.new(calendar_rule, max_projected_bytes: at_budget - 1).transpile }
            .to raise_error(Gitlab::PolicyStore::ValidationError,
              /windows project to #{at_budget} bytes, over the maximum of #{at_budget - 1} bytes/)
        end
      end

      context "when no single window exceeds the budget but their combined size does" do
        let(:windows) do
          Array.new(5) do |index|
            { name: "w#{index}", tiers: ["production"], starts_at: "2026-12-24T00:00:00Z",
              ends_at: "2027-01-02T00:00:00Z" }
          end
        end

        let(:rule) { { type: "calendar", value: { windows: windows } } }
        let(:max_projected_bytes) { JSON.generate(windows.first).bytesize }

        it "rejects when no single window exceeds the budget but their combined size does" do
          expect { rego }.to raise_error(Gitlab::PolicyStore::ValidationError, /windows project to \d+ bytes/)
        end

        it "stops estimating windows once the running total already exceeds the budget" do
          max_projected_bytes # force the budget to be computed before we start counting calls

          expect(JSON).to receive(:generate).twice.and_call_original

          expect { rego }.to raise_error(Gitlab::PolicyStore::ValidationError, /windows project to \d+ bytes/)
        end
      end

      context "with a malformed window alongside a valid one in the same rule" do
        let(:rule) do
          { type: "calendar",
            value: { windows: [{ name: "eoq\xFF", tiers: ["production"], starts_at: "2026-12-24T00:00:00Z",
                                 ends_at: "2027-01-02T00:00:00Z" },
              { name: "second", tiers: ["production"], starts_at: "2027-01-01T00:00:00Z",
                ends_at: "2027-01-02T00:00:00Z" }] } }
        end

        let(:max_projected_bytes) { 10 }

        it "does not partially charge the malformed window's bytes" do
          expect { rego }
            .to raise_error(Gitlab::PolicyStore::ValidationError, "rule 0: calendar window 0 requires a name")
        end
      end

      context "with an exact-duplicate window repeated ten times" do
        let(:single_window) do
          { name: "eoq", tiers: ["production"], starts_at: "2026-12-24T00:00:00Z", ends_at: "2027-01-02T00:00:00Z" }
        end

        let(:rule) { { type: "calendar", value: { windows: Array.new(10) { single_window } } } }
        let(:max_projected_bytes) { JSON.generate(single_window).bytesize * 2 }

        # 10 copies would blow a budget sized for 2 windows if charged individually, but the
        # compiled program only ever emits one window after dedup.
        it "charges it once, matching what the compiled program actually charges" do
          expect(rego).to include("freeze_window")
        end
      end

      context "with a window that cannot be JSON-encoded for the estimate" do
        let(:rule) { calendar_rule(name: "eoq\xFF") }
        let(:max_projected_bytes) { 10 }

        it "still reaches the normal window validation" do
          expect { rego }
            .to raise_error(Gitlab::PolicyStore::ValidationError, "rule 0: calendar window 0 requires a name")
        end
      end

      context "with a window too deeply nested to estimate" do
        let(:rule) do
          deeply_nested = {}
          cursor = deeply_nested
          101.times do |index|
            cursor[index.to_s] = {}
            cursor = cursor[index.to_s]
          end
          calendar_rule(ends_at: deeply_nested)
        end

        let(:max_projected_bytes) { 10 }

        it "still reaches the normal window validation, rather than raising JSON::NestingError" do
          expect { rego }
            .to raise_error(Gitlab::PolicyStore::ValidationError, 'rule 0: calendar window "eoq" requires ends_at')
        end
      end
    end

    context "with input coercion" do
      it "treats string and symbol keys identically (jsonb round-trips as strings)" do
        with_symbols = described_class.new({ type: "environment", value: { names: ["production"] } }).transpile
        with_strings = described_class.new(
          { "type" => "environment", "value" => { "names" => ["production"] } }
        ).transpile

        expect(with_strings).to eq(with_symbols)
      end

      context "with names authored out of order and repeated" do
        let(:rule) { { type: "environment", value: { names: %w[staging production staging] } } }

        it "deduplicates and sorts names, so authoring order does not change the stored text" do
          expect(rego).to include('input.environment.name in {"production", "staging"}')
        end
      end

      context "with entries that are not usable strings" do
        let(:rule) { { type: "environment", value: { names: [42, "", "  ", nil, "production"] } } }

        it "drops entries that are not usable strings" do
          expect(rego).to include('input.environment.name in {"production"}')
        end
      end
    end

    context "with a rule it cannot compile" do
      def expect_invalid(rule, message, rule_index: 3)
        expect { described_class.new(rule, rule_index: rule_index).transpile }
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

      it "rejects a window name whose bytes are not valid UTF-8" do
        expect_invalid({ type: "calendar", value: { windows: [{ name: "eoq\xFF", tiers: ["production"] }] } },
          "calendar window 0 requires a name")
      end

      it "rejects an environment rule with neither names nor tiers" do
        expect_invalid({ type: "environment", value: {} },
          "environment rule requires at least one of names or tiers")
      end

      it "rejects an environment rule whose names are all unusable" do
        expect_invalid({ type: "environment", value: { names: [""], tiers: [] } },
          "environment rule requires at least one of names or tiers")
      end

      it "rejects a calendar rule with no windows" do
        expect_invalid({ type: "calendar", value: { windows: [] } },
          "calendar rule requires at least one window")
      end

      it "rejects a window with no name, which the violation message reports" do
        expect_invalid({ type: "calendar", value: { windows: [{ tiers: ["production"] }] } },
          "calendar window 0 requires a name")
      end

      it "reports the position of an invalid window among otherwise-valid ones" do
        expect_invalid(
          { type: "calendar",
            value: { windows: [{ name: "first",
                                 tiers: ["production"],
                                 starts_at: "2026-01-01T00:00:00Z",
                                 ends_at: "2026-01-02T00:00:00Z" },
              { tiers: ["production"] }] } },
          "calendar window 1 requires a name"
        )
      end

      it "rejects a window with no tiers, which would never match" do
        expect_invalid({ type: "calendar", value: { windows: [{ name: "eoq" }] } },
          'calendar window "eoq" requires at least one tier')
      end

      it "rejects a window that is not an object" do
        expect_invalid({ type: "calendar", value: { windows: ["2026-12-24"] } },
          "calendar window 0 must be an object")
      end

      it "rejects a window that ends before it starts" do
        expect_invalid(
          calendar_rule(starts_at: "2027-01-02T00:00:00Z", ends_at: "2026-12-24T00:00:00Z"),
          'calendar window "eoq" ends before it starts'
        )
      end

      it "rejects a zero-length window" do
        expect_invalid(
          calendar_rule(ends_at: "2026-12-24T00:00:00Z"),
          'calendar window "eoq" ends before it starts'
        )
      end

      it "rejects windows authored as an object rather than a list" do
        expect_invalid({ type: "calendar", value: { windows: { name: "eoq" } } },
          "calendar rule requires at least one window")
      end

      it "rejects a calendar rule whose value is not an object" do
        expect_invalid({ type: "calendar", value: "2026-12-24T00:00:00Z" },
          "calendar rule requires at least one window")
      end

      it "rejects an environment rule whose value is not an object" do
        expect_invalid({ type: "environment", value: "production" },
          "environment rule requires at least one of names or tiers")
      end

      it "has an emitter for every rule type the catalogue advertises", :aggregate_failures do
        refusal_for_an_empty_rule = {
          "custom" => "custom rule requires Rego source in value",
          "calendar" => "calendar rule requires at least one window",
          "environment" => "environment rule requires at least one of names or tiers"
        }

        expect(refusal_for_an_empty_rule.keys)
          .to match_array(Gitlab::PolicyStore::Rules::ALL.map { |rule| rule[:id] })

        refusal_for_an_empty_rule.each do |rule_type, message|
          expect_invalid({ type: rule_type }, message, rule_index: 0)
        end
      end
    end

    context "with text the emitted program could not carry" do
      context "with a name whose bytes cannot reach UTF-8" do
        let(:rule) { { type: "environment", value: { names: ["prod\xFF".b] } } }

        it "refuses it, rather than raising from the encoder" do
          expect { rego }
            .to raise_error(Gitlab::PolicyStore::ValidationError,
              'rule 0: value cannot be encoded as UTF-8: "prod\xFF"')
        end
      end

      context "with a window name whose bytes cannot reach UTF-8" do
        let(:rule) do
          window = { name: "eoq\xFF".b, tiers: ["production"],
                     starts_at: "2026-12-24T00:00:00Z", ends_at: "2027-01-02T00:00:00Z" }
          { type: "calendar", value: { windows: [window] } }
        end

        it "refuses it" do
          expect { rego }
            .to raise_error(Gitlab::PolicyStore::ValidationError,
              'rule 0: value cannot be encoded as UTF-8: "eoq\xFF"')
        end
      end

      context "with a custom program that is not UTF-8" do
        let(:rule) { { type: "custom", value: "package governance\n".encode("UTF-16LE") } }

        it "refuses it, which the package scan cannot even read" do
          expect { rego }
            .to raise_error(Gitlab::PolicyStore::ValidationError,
              "rule 0: custom rule source must be UTF-8, found UTF-16LE")
        end
      end

      context "with a custom program in a dummy encoding" do
        let(:rule) { { type: "custom", value: "package governance\n".encode("UTF-16") } }

        it "refuses it, which cannot even be stripped" do
          expect { rego }
            .to raise_error(Gitlab::PolicyStore::ValidationError,
              "rule 0: custom rule source must be UTF-8, found UTF-16")
        end
      end

      context "with a name in a dummy encoding" do
        let(:rule) { { type: "environment", value: { names: ["production".encode("UTF-16")] } } }

        it "refuses it rather than raising from the strip" do
          expect { rego }
            .to raise_error(Gitlab::PolicyStore::ValidationError,
              "rule 0: environment rule requires at least one of names or tiers")
        end
      end

      context "with an ASCII-only program tagged with a binary encoding" do
        let(:program) { "package governance\n\nallow := true\n" }
        let(:rule) { { type: "custom", value: program.b } }

        it "accepts it whatever encoding it is tagged with, since it reaches UTF-8" do
          expect(rego).to eq(program)
        end
      end

      context "with a name that transcodes cleanly" do
        let(:rule) { { type: "environment", value: { names: ["production".encode("UTF-16LE")] } } }

        it "accepts it" do
          expect(rego).to include('input.environment.name in {"production"}')
        end
      end
    end

    context "with a value too large to echo back" do
      context "with an unsupported type name 200 characters long" do
        let(:rule) { { type: "z" * 200 } }

        it "names the type by its length rather than repeating it" do
          expect { rego }
            .to raise_error(Gitlab::PolicyStore::ValidationError,
              "rule 0: unsupported rule type #{('z' * 64).inspect} (200 characters)")
        end
      end

      context "with a type that is not a string" do
        let(:rule) { { type: 10**5_000_000 } }

        it "names it by its type, since rendering one can be superlinear" do
          expect { rego }
            .to raise_error(Gitlab::PolicyStore::ValidationError, "rule 0: unsupported rule type Integer")
        end
      end

      context "with a window name 200 characters long" do
        let(:rule) { { type: "calendar", value: { windows: [{ name: "w" * 200 }] } } }

        it "elides the name it reports" do
          expect { rego }
            .to raise_error(Gitlab::PolicyStore::ValidationError,
              "rule 0: calendar window #{('w' * 64).inspect} (200 characters) requires at least one tier")
        end
      end
    end

    context "with a rule index a caller supplied" do
      let(:rule) { { type: "environment", value: { tiers: ["production"] } } }
      let(:rule_index) { "0\n\nviolation contains {\"msg\": \"injected\"} if { true }\n\n# " }

      it "coerces it, so it cannot carry Rego into the emitted program", :aggregate_failures do
        expect(rego).to include("# rule 0: environment")
        expect(rego).not_to include("injected")
      end
    end
  end
end
