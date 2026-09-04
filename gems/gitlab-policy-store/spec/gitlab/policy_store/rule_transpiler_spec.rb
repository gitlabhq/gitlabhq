# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::PolicyStore::RuleTranspiler do
  def fixture_rego(name)
    File.read(File.expand_path("../../fixtures/rules/#{name}/rule.rego", __dir__))
  end

  def transpile(rule, rule_index: 0, max_projected_bytes: nil)
    described_class.new(rule, rule_index: rule_index, max_projected_bytes: max_projected_bytes).transpile
  end

  def calendar_rule(**overrides)
    { type: "calendar",
      value: { windows: [{ name: "eoq",
                           tiers: ["production"],
                           starts_at: "2026-12-24T00:00:00Z",
                           ends_at: "2027-01-02T00:00:00Z" }.merge(overrides)] } }
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

      it "regenerates calendar_window byte-for-byte" do
        rego = transpile(
          { type: "calendar",
            value: { windows: [{ name: "eoq-freeze",
                                 tiers: ["production"],
                                 starts_at: "2026-12-24T00:00:00Z",
                                 ends_at: "2027-01-02T00:00:00Z" }] } }
        )

        expect(rego).to eq(fixture_rego("calendar_window"))
      end

      it "regenerates calendar_windows_with_offsets byte-for-byte" do
        rego = transpile(
          { type: "calendar",
            value: { windows: [{ name: "summit",
                                 tiers: %w[production staging],
                                 starts_at: "2026-09-01T12:00:00+02:00",
                                 ends_at: "2026-09-03T00:00:00Z" },
              { name: "eoq-freeze",
                tiers: ["production"],
                starts_at: "2026-12-24T00:00:00Z",
                ends_at: "2027-01-02T00:00:00Z" }] } },
          rule_index: 2
        )

        expect(rego).to eq(fixture_rego("calendar_windows_with_offsets"))
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

    context "with a calendar rule" do
      def windows_from(rego)
        rego[/freeze_window := \[\n(.*?)\n\t\]\[_\]/m, 1].lines.map(&:strip)
      end

      it "normalizes an authored offset to UTC, so the emitted comparison holds", :aggregate_failures do
        rego = transpile(
          calendar_rule(starts_at: "2026-09-01T12:00:00+02:00", ends_at: "2026-09-03T01:30:00-01:00")
        )

        expect(rego).to include('"starts_at": "2026-09-01T10:00:00Z"')
        expect(rego).to include('"ends_at": "2026-09-03T02:30:00Z"')
      end

      it "does not compile a bound whose meaning depends on the host time zone" do
        expect { transpile(calendar_rule(starts_at: "2026-09-01T00:00:00")) }
          .to raise_error(Gitlab::PolicyStore::ValidationError, /starts_at must be an RFC 3339 instant/)
      end

      it "accepts an offset written without a colon" do
        rego = transpile(calendar_rule(starts_at: "2026-09-01T12:00:00+0200"))

        expect(rego).to include('"starts_at": "2026-09-01T10:00:00Z"')
      end

      it "accepts a lowercase zone designator, which the parser reads and the emitter normalizes" do
        rego = transpile(calendar_rule(starts_at: "2026-12-24T00:00:00z"))

        expect(rego).to include('"starts_at": "2026-12-24T00:00:00Z"')
      end

      it "accepts a lowercase date separator, which RFC 3339 permits" do
        rego = transpile(calendar_rule(starts_at: "2026-12-24t00:00:00Z"))

        expect(rego).to include('"starts_at": "2026-12-24T00:00:00Z"')
      end

      it "accepts a leap day in a leap year, which the date check must not read as non-existent" do
        rego = transpile(calendar_rule(starts_at: "2028-02-29T00:00:00Z", ends_at: "2028-03-05T00:00:00Z"))

        expect(rego).to include('"starts_at": "2028-02-29T00:00:00Z"')
      end

      it "accepts a zero fraction, which drops without changing the instant" do
        rego = transpile(calendar_rule(starts_at: "2026-12-24T00:00:00.000Z"))

        expect(rego).to include('"starts_at": "2026-12-24T00:00:00Z"')
      end

      it "keeps windows in the authored order" do
        rego = transpile(
          { type: "calendar",
            value: { windows: [{ name: "second",
                                 tiers: ["production"],
                                 starts_at: "2027-01-01T00:00:00Z",
                                 ends_at: "2027-01-02T00:00:00Z" },
              { name: "first",
                tiers: ["production"],
                starts_at: "2026-01-01T00:00:00Z",
                ends_at: "2026-01-02T00:00:00Z" }] } }
        )

        expect(windows_from(rego)).to match([
          a_string_including('"name": "second"'),
          a_string_including('"name": "first"')
        ])
      end

      it "de-duplicates windows that are identical after normalization" do
        rego = transpile(
          { type: "calendar",
            value: { windows: [{ name: "eoq", tiers: ["production"], starts_at: "2026-12-24T00:00:00Z",
                                 ends_at: "2027-01-02T00:00:00Z" },
              { name: "eoq", tiers: ["production"], starts_at: "2026-12-24T00:00:00Z",
                ends_at: "2027-01-02T00:00:00Z" }] } }
        )

        expect(windows_from(rego).length).to eq(1)
      end

      it "de-duplicates windows naming the same instant in different authored forms" do
        rego = transpile(
          { type: "calendar",
            value: { windows: [{ name: "eoq", tiers: ["production"], starts_at: "2026-09-01T12:00:00+02:00",
                                 ends_at: "2026-09-03T01:30:00-01:00" },
              { name: "eoq", tiers: ["production"], starts_at: "2026-09-01T10:00:00Z",
                ends_at: "2026-09-03T02:30:00Z" }] } }
        )

        expect(windows_from(rego).length).to eq(1)
      end

      it "keeps windows with the same name but different tiers, since a name alone is not a duplicate" do
        rego = transpile(
          { type: "calendar",
            value: { windows: [{ name: "eoq", tiers: ["production"], starts_at: "2026-12-24T00:00:00Z",
                                 ends_at: "2027-01-02T00:00:00Z" },
              { name: "eoq", tiers: ["staging"], starts_at: "2026-12-24T00:00:00Z",
                ends_at: "2027-01-02T00:00:00Z" }] } }
        )

        expect(windows_from(rego).length).to eq(2)
      end

      it "de-duplicates windows even when the duplicate is not adjacent in authored order" do
        rego = transpile(
          { type: "calendar",
            value: { windows: [{ name: "eoq", tiers: ["production"], starts_at: "2026-12-24T00:00:00Z",
                                 ends_at: "2027-01-02T00:00:00Z" },
              { name: "second", tiers: ["production"], starts_at: "2027-06-01T00:00:00Z",
                ends_at: "2027-06-02T00:00:00Z" },
              { name: "eoq", tiers: ["production"], starts_at: "2026-12-24T00:00:00Z",
                ends_at: "2027-01-02T00:00:00Z" }] } }
        )

        expect(windows_from(rego).length).to eq(2)
      end

      it "keeps the windows out of the package document, so two calendar rules can merge" do
        expect(transpile(calendar_rule)).not_to match(/^\S+\s*:?=/)
      end

      it "binds the window without `some`, which a package-level rule of the same name would break",
        :aggregate_failures do
        rego = transpile(calendar_rule)

        expect(rego).to include("freeze_window := [")
        expect(rego).not_to include("some freeze_window")
      end

      it "carries the rule index in the violation, which a merged module needs to tell rules apart" do
        expect(transpile(calendar_rule, rule_index: 3)).to include('"rule_index": 3')
      end

      it "rejects windows whose raw size alone exceeds an injected byte budget" do
        expect { transpile(calendar_rule, max_projected_bytes: 10) }
          .to raise_error(Gitlab::PolicyStore::ValidationError,
            /windows project to \d+ bytes, over the maximum of 10 bytes/)
      end

      it "accepts windows whose raw size is within an injected byte budget" do
        expect(transpile(calendar_rule, max_projected_bytes: 1_000_000)).to include("freeze_window")
      end

      it "does not check the byte budget when none is injected, the default for every other example here" do
        expect(transpile(calendar_rule)).to include("freeze_window")
      end

      it "rejects on projected size before a malformed window would otherwise be rejected first" do
        malformed = calendar_rule(starts_at: "not-a-timestamp")

        expect { transpile(malformed, max_projected_bytes: 10) }
          .to raise_error(Gitlab::PolicyStore::ValidationError,
            /windows project to \d+ bytes, over the maximum of 10 bytes/)
      end

      it "accepts windows whose projected size is exactly at the budget, and rejects one byte over",
        :aggregate_failures do
        at_budget = JSON.generate({ "name" => "eoq", "tiers" => ["production"],
                                     "starts_at" => "2026-12-24T00:00:00Z", "ends_at" => "2027-01-02T00:00:00Z" })
          .bytesize

        expect(transpile(calendar_rule, max_projected_bytes: at_budget)).to include("freeze_window")
        expect { transpile(calendar_rule, max_projected_bytes: at_budget - 1) }
          .to raise_error(Gitlab::PolicyStore::ValidationError,
            /windows project to #{at_budget} bytes, over the maximum of #{at_budget - 1} bytes/)
      end

      it "rejects when no single window exceeds the budget but their combined size does" do
        windows = Array.new(5) do |index|
          { name: "w#{index}", tiers: ["production"], starts_at: "2026-12-24T00:00:00Z",
            ends_at: "2027-01-02T00:00:00Z" }
        end
        single_window_bytesize = JSON.generate(windows.first).bytesize
        rule = { type: "calendar", value: { windows: windows } }

        expect { transpile(rule, max_projected_bytes: single_window_bytesize) }
          .to raise_error(Gitlab::PolicyStore::ValidationError, /windows project to \d+ bytes/)
      end

      it "does not partially charge a malformed window's bytes when another window in the same rule is valid" do
        windows = [{ name: "eoq\xFF", tiers: ["production"], starts_at: "2026-12-24T00:00:00Z",
                     ends_at: "2027-01-02T00:00:00Z" },
          { name: "second", tiers: ["production"], starts_at: "2027-01-01T00:00:00Z",
            ends_at: "2027-01-02T00:00:00Z" }]
        rule = { type: "calendar", value: { windows: windows } }

        expect { transpile(rule, max_projected_bytes: 10) }
          .to raise_error(Gitlab::PolicyStore::ValidationError, "rule 0: calendar window 0 requires a name")
      end

      it "charges an exact-duplicate window once, matching what the compiled program actually charges" do
        single_window = { name: "eoq", tiers: ["production"], starts_at: "2026-12-24T00:00:00Z",
                          ends_at: "2027-01-02T00:00:00Z" }
        single_window_bytesize = JSON.generate(single_window).bytesize
        rule = { type: "calendar", value: { windows: Array.new(10) { single_window } } }

        # 10 copies would blow a budget sized for 2 windows if charged individually, but the
        # compiled program only ever emits one window after dedup.
        expect(transpile(rule, max_projected_bytes: single_window_bytesize * 2)).to include("freeze_window")
      end

      it "stops estimating windows once the running total already exceeds the budget" do
        windows = Array.new(5) do |index|
          { name: "w#{index}", tiers: ["production"], starts_at: "2026-12-24T00:00:00Z",
            ends_at: "2027-01-02T00:00:00Z" }
        end
        single_window_bytesize = JSON.generate(windows.first).bytesize
        rule = { type: "calendar", value: { windows: windows } }

        expect(JSON).to receive(:generate).twice.and_call_original

        expect { transpile(rule, max_projected_bytes: single_window_bytesize) }
          .to raise_error(Gitlab::PolicyStore::ValidationError, /windows project to \d+ bytes/)
      end

      it "still reaches the normal window validation when a window cannot be JSON-encoded for the estimate" do
        malformed = calendar_rule(name: "eoq\xFF")

        expect { transpile(malformed, max_projected_bytes: 10) }
          .to raise_error(Gitlab::PolicyStore::ValidationError, "rule 0: calendar window 0 requires a name")
      end

      it "still reaches the normal window validation, rather than raising JSON::NestingError, when a window " \
        "is too deeply nested to estimate" do
        deeply_nested = {}
        cursor = deeply_nested
        101.times do |index|
          cursor[index.to_s] = {}
          cursor = cursor[index.to_s]
        end
        malformed = calendar_rule(ends_at: deeply_nested)

        expect { transpile(malformed, max_projected_bytes: 10) }
          .to raise_error(Gitlab::PolicyStore::ValidationError, 'rule 0: calendar window "eoq" requires ends_at')
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

      it "rejects a window with a missing bound" do
        expect_invalid(
          { type: "calendar", value: { windows: [{ name: "eoq", tiers: ["production"] }] } },
          'calendar window "eoq" requires starts_at'
        )
      end

      it "rejects a window that is not an object" do
        expect_invalid({ type: "calendar", value: { windows: ["2026-12-24"] } },
          "calendar window 0 must be an object")
      end

      it "names the shape, not the calendar, when a two-digit year would parse leniently" do
        expect_invalid(
          calendar_rule(starts_at: "26-12-24T00:00:00Z"),
          'calendar window "eoq" starts_at must be an RFC 3339 instant such as ' \
            '`2026-12-24T00:00:00Z`: "26-12-24T00:00:00Z"'
        )
      end

      it "rejects a five-digit year, which is not the shape an instant takes" do
        expect_invalid(
          calendar_rule(starts_at: "10000-01-01T00:00:00Z", ends_at: "3000-01-01T00:00:00Z"),
          'calendar window "eoq" starts_at must be an RFC 3339 instant such as ' \
            '`2026-12-24T00:00:00Z`: "10000-01-01T00:00:00Z"'
        )
      end

      it "rejects an instant whose UTC form the string comparison cannot order" do
        expect_invalid(
          calendar_rule(starts_at: "9999-12-31T23:00:00-05:00", ends_at: "3000-01-01T00:00:00Z"),
          'calendar window "eoq" starts_at is outside the range the emitted comparison can order: ' \
            '"9999-12-31T23:00:00-05:00"'
        )
      end

      it "rejects a bound finer than the second the comparison comes down to" do
        expect_invalid(
          calendar_rule(ends_at: "2027-01-02T23:59:59.999Z"),
          'calendar window "eoq" ends_at carries sub-second precision the emitted comparison ' \
            'cannot represent: "2027-01-02T23:59:59.999Z"'
        )
      end

      it "rejects a bound too long to be an instant before parsing it, since the parse is the cost" do
        too_long = "#{'9' * 1_000_000}-01-01T00:00:00Z"

        expect_invalid(
          calendar_rule(starts_at: too_long),
          "calendar window \"eoq\" starts_at is longer than any instant: " \
            "#{('9' * 64).inspect} (#{too_long.length} characters)"
        )
      end

      it "rejects a date that does not exist, rather than rolling it into the next month" do
        expect_invalid(
          calendar_rule(starts_at: "2026-06-31T10:00:00Z"),
          'calendar window "eoq" starts_at names a date or time that does not exist: ' \
            '"2026-06-31T10:00:00Z"'
        )
      end

      it "rejects a leap day in a non-leap year" do
        expect_invalid(
          calendar_rule(starts_at: "2027-02-29T00:00:00Z", ends_at: "2027-03-05T00:00:00Z"),
          'calendar window "eoq" starts_at names a date or time that does not exist: ' \
            '"2027-02-29T00:00:00Z"'
        )
      end

      it "rejects a leap second, which would move the boundary a second without saying so" do
        expect_invalid(
          calendar_rule(starts_at: "2026-12-31T23:59:60Z"),
          'calendar window "eoq" starts_at names a date or time that does not exist: ' \
            '"2026-12-31T23:59:60Z"'
        )
      end

      it "rejects an hour of 24, which names the following midnight" do
        expect_invalid(
          calendar_rule(starts_at: "2026-06-15T24:00:00Z"),
          'calendar window "eoq" starts_at names a date or time that does not exist: ' \
            '"2026-06-15T24:00:00Z"'
        )
      end

      it "rejects a timestamp it cannot parse" do
        expect_invalid(
          calendar_rule(starts_at: "2026-13-45T00:00:00Z"),
          'calendar window "eoq" has an unparsable starts_at: "2026-13-45T00:00:00Z"'
        )
      end

      it "rejects free text before trying to parse it" do
        expect_invalid(
          calendar_rule(starts_at: "next tuesday"),
          'calendar window "eoq" starts_at must be an RFC 3339 instant such as ' \
            '`2026-12-24T00:00:00Z`: "next tuesday"'
        )
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
      it "refuses a name whose bytes cannot reach UTF-8, rather than raising from the encoder" do
        expect { transpile({ type: "environment", value: { names: ["prod\xFF".b] } }) }
          .to raise_error(Gitlab::PolicyStore::ValidationError,
            'rule 0: value cannot be encoded as UTF-8: "prod\xFF"')
      end

      it "refuses a bound in an encoding the offset match cannot read, rather than raising from the match" do
        window = { name: "eoq", tiers: ["production"],
                   starts_at: "2026-12-24T00:00:00Z".encode("UTF-16LE"), ends_at: "2027-01-02T00:00:00Z" }

        expect { transpile({ type: "calendar", value: { windows: [window] } }) }
          .to raise_error(Gitlab::PolicyStore::ValidationError,
            'rule 0: calendar window "eoq" starts_at must be ASCII to be an ISO 8601 instant, not UTF-16LE')
      end

      it "refuses a window name whose bytes cannot reach UTF-8" do
        window = { name: "eoq\xFF".b, tiers: ["production"],
                   starts_at: "2026-12-24T00:00:00Z", ends_at: "2027-01-02T00:00:00Z" }

        expect { transpile({ type: "calendar", value: { windows: [window] } }) }
          .to raise_error(Gitlab::PolicyStore::ValidationError,
            'rule 0: value cannot be encoded as UTF-8: "eoq\xFF"')
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

      it "elides a window name it reports" do
        expect { transpile({ type: "calendar", value: { windows: [{ name: "w" * 200 }] } }) }
          .to raise_error(Gitlab::PolicyStore::ValidationError,
            "rule 0: calendar window #{('w' * 64).inspect} (200 characters) requires at least one tier")
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
