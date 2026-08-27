# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::PolicyStore::ScopeTranspiler do
  def fixture_rego(name)
    File.read(File.expand_path("../../fixtures/scope/#{name}/policy.rego", __dir__))
  end

  def fixture_dimensions(name)
    JSON.parse(File.read(File.expand_path("../../fixtures/scope/#{name}/dimensions.json", __dir__)))
  end

  def transpile_including(*entries)
    described_class.new({ "projects" => { "including" => entries } }, policy_name: "P").transpile
  end

  def transpile_excluding(*entries)
    described_class.new({ "projects" => { "excluding" => entries } }, policy_name: "P").transpile
  end

  describe ".transpile" do
    # Whole-string comparison against committed fixtures, rather than matching
    # fragments, because `scope_rego` is stored and evaluated as text. Its
    # whitespace and rule ordering are part of what we ship, and fragment
    # matching would let them drift unnoticed.
    context "with golden fixtures" do
      it "regenerates no_scope byte-for-byte" do
        transpiler = described_class.new(nil, policy_name: "Applies everywhere")

        expect(transpiler.transpile).to eq(fixture_rego("no_scope"))
        expect(transpiler.scope_dimensions).to eq(fixture_dimensions("no_scope"))
      end

      it "regenerates applies_framework byte-for-byte" do
        transpiler = described_class.new(
          { compliance_frameworks: [{ id: 5 }], projects: { excluding: [{ type: "archived" }] } },
          policy_name: "Scoped to compliance framework 5"
        )

        expect(transpiler.transpile).to eq(fixture_rego("applies_framework"))
        expect(transpiler.scope_dimensions).to eq(fixture_dimensions("applies_framework"))
      end

      it "regenerates groups_any byte-for-byte" do
        transpiler = described_class.new(
          { match_mode: "any", groups: { including: [{ id: 10 }] }, business_impact: { including: [{ id: 1 }] } },
          policy_name: "Scoped to groups (any)"
        )

        expect(transpiler.transpile).to eq(fixture_rego("groups_any"))
        expect(transpiler.scope_dimensions).to eq(fixture_dimensions("groups_any"))
      end

      it "regenerates excluded_archived byte-for-byte" do
        transpiler = described_class.new(
          { projects: { excluding: [{ type: "archived" }] } },
          policy_name: "Excluding archived projects"
        )

        expect(transpiler.transpile).to eq(fixture_rego("excluded_archived"))
        expect(transpiler.scope_dimensions).to eq(fixture_dimensions("excluded_archived"))
      end
    end

    context "with individual scope constructs" do
      it "emits a scoped block with include (all) + exclude, ending in a total applies rule" do
        rego = described_class.new(
          {
            match_mode: "all",
            compliance_frameworks: [{ id: 5 }],
            projects: { including: [{ id: 42 }, { id: 43 }], excluding: [{ id: 77 }, { type: "archived" }] }
          },
          policy_name: "Block denied licenses"
        ).transpile

        expect(rego).to include("package gitlab.scope")
        expect(rego).to include('# policy "Block denied licenses" (match_mode: all)')
        expect(rego).to include("default excluded := false")
        expect(rego).to include("input.project.id in {77}")
        expect(rego).to include("input.project.archived == true")
        expect(rego).to include("some framework_id in input.compliance_frameworks")
        expect(rego).to include("framework_id in {5}")
        expect(rego).to include("input.project.id in {42, 43}")
        expect(rego).to include("default applies := false")
        expect(rego).to include("applies if {\n\tnot excluded\n\tincluded\n}")
      end

      # The engine queries `data.gitlab.scope.applies` and nothing else, so any further
      # rule would be text nobody reads in a stored, length-capped column. An earlier
      # revision exposed a `results` set and `applicable`/`not_applicable`/`applicability`
      # aggregates over it, which only pay off when several policies' programs answer in
      # one query, and these rule names are not namespaced per policy, so co-loading them
      # into one engine ORs them into each other instead.
      it "exposes no rule beyond applies and the two it is derived from" do
        rego = described_class.new({ compliance_frameworks: [{ id: 5 }] }, policy_name: "P").transpile

        rule_names = rego.scan(/^(?:default )?(\w+)(?= if | := )/).flatten.uniq

        expect(rule_names).to contain_exactly("excluded", "included", "applies")
      end

      it "emits one included body per dimension for match_mode any" do
        rego = described_class.new(
          { match_mode: "any", groups: { including: [{ id: 10 }] }, business_impact: { including: [{ id: 1 }] } },
          policy_name: "P"
        ).transpile

        expect(rego.scan("included if {").length).to eq(2)
        expect(rego).to include("some group_id in input.groups")
        expect(rego).to include("some business_impact_id in input.security_attributes.business_impact")
      end

      it "emits an unconditional applies rule for a no-scope (empty) policy" do
        rego = described_class.new({}, policy_name: "Unscoped").transpile

        expect(rego).to include('# policy "Unscoped"')
        expect(rego).to include("no policy_scope: applies to all projects")
        expect(rego).to include("applies := true")
        expect(rego).not_to include("default applies")
      end

      it "emits a constant included rule when only excludes are present" do
        rego = described_class.new(
          { projects: { excluding: [{ id: 9 }] } },
          policy_name: "P"
        ).transpile

        expect(rego).to include("included if { true }")
      end
    end

    context "with input coercion" do
      it "accepts bare integer ids as well as { id: n } hashes" do
        from_hashes = described_class.new({ compliance_frameworks: [{ id: 5 }] }, policy_name: "P").transpile
        from_ints = described_class.new({ compliance_frameworks: [5] }, policy_name: "P").transpile

        expect(from_ints).to eq(from_hashes)
      end

      it "deduplicates and sorts ids, so authoring order does not change the stored text" do
        rego = described_class.new(
          { projects: { including: [{ id: 5 }, { id: 3 }, { id: 5 }] } },
          policy_name: "P"
        ).transpile

        expect(rego).to include("input.project.id in {3, 5}")
      end

      it "treats string and symbol keys identically (jsonb round-trips as strings)" do
        with_symbols = described_class.new({ groups: { including: [{ id: 10 }] } }, policy_name: "P").transpile
        string_keyed_scope = { "groups" => { "including" => [{ "id" => 10 }] } }
        with_strings = described_class.new(string_keyed_scope, policy_name: "P").transpile

        expect(with_strings).to eq(with_symbols)
      end

      it "treats string and symbol values identically" do
        symbol_valued = { match_mode: :any, groups: { including: [{ id: 10 }] } }
        round_tripped = JSON.parse(JSON.generate(symbol_valued))

        expect(described_class.new(symbol_valued, policy_name: "P").transpile)
          .to eq(described_class.new(round_tripped, policy_name: "P").transpile)
      end

      it "honours a symbol project type in an excluding entry" do
        rego = described_class.new({ projects: { excluding: [{ type: :personal }] } }, policy_name: "P").transpile

        expect(rego).to include("personal")
      end

      it "accepts ids delivered as strings, as a form-encoded request sends them" do
        from_strings = described_class.new(
          { "compliance_frameworks" => [{ "id" => "5" }] },
          policy_name: "P"
        ).transpile
        from_integers = described_class.new({ compliance_frameworks: [{ id: 5 }] }, policy_name: "P").transpile

        expect(from_strings).to eq(from_integers)
      end

      it "accepts bare string ids as well as { id: \"n\" } hashes" do
        rego = described_class.new(
          { "projects" => { "including" => ["5", { "id" => "3" }] } },
          policy_name: "P"
        ).transpile

        expect(rego).to include("input.project.id in {3, 5}")
      end

      it "keeps an entry that declares a condition without naming an id" do
        rego = described_class.new({ "projects" => { "including" => [{}] } }, policy_name: "P").transpile

        expect(rego).to include("input.project.id in set()")
      end

      it "keeps an entry whose id is null, since a null names no id either" do
        rego = transpile_excluding(nil, { "id" => 7 })

        expect(rego).to include("input.project.id in {7}")
      end

      it "accepts a padded id, since the padding does not change which id it names" do
        expect(transpile_including("007")).to include("input.project.id in {7}")
      end

      [
        ["a string carrying more than an id", "1; injected"],
        ["a fractional id", "3.5"],
        ["a fractional id that is not a string", 3.5],
        ["a boolean", true],
        ["an id wrapped in an array", [5]],
        ["a digit run too long to be worth parsing", "9" * 21],
        ["an id with a trailing newline, as a text field sends it", "5\n"],
        ["a non-ASCII digit", "١٢٣"],
        ["an id in a non-ASCII encoding", "5".encode("UTF-16")]
      ].each do |description, value|
        it "raises ValidationError for #{description}, rather than silently dropping it" do
          expect { transpile_including(value) }
            .to raise_error(Gitlab::PolicyStore::ValidationError, /is not an id/)
        end
      end

      it "raises ValidationError for an id whose bytes are not valid UTF-8, not an encoding error" do
        invalid_utf8 = (+"\xFF5").force_encoding("UTF-8")

        expect { transpile_including(invalid_utf8) }
          .to raise_error(Gitlab::PolicyStore::ValidationError, /text that is not valid UTF-8/)
      end

      it "names the encoding when that is what refused the id, since the bytes can read as one" do
        expect { transpile_including("5".encode("UTF-32BE")) }
          .to raise_error(Gitlab::PolicyStore::ValidationError, /text encoded as UTF-32BE/)
      end

      it "refuses a value that is not an id wherever it is authored, not only under projects" do
        expect { described_class.new({ "groups" => { "including" => ["1; injected"] } }, policy_name: "P").transpile }
          .to raise_error(Gitlab::PolicyStore::ValidationError, /is not an id/)
      end

      it "names the offending value, so the caller can find it" do
        expect { transpile_including(3, "1; injected") }
          .to raise_error(Gitlab::PolicyStore::ValidationError, /"1; injected"/)
      end

      [
        ["a zero id", 0],
        ["a zero id delivered as a string", "0"],
        ["a negative Integer id", -2],
        ["a negative id delivered as a string", "-2"],
        ["the widest negative id, sign included", "-9223372036854775807"],
        ["an Integer past the widest a bigint holds", 9_223_372_036_854_775_808],
        ["a string past the widest a bigint holds", "9223372036854775808"],
        ["a digit run one longer than any id", "9" * 20]
      ].each do |description, value|
        it "raises ValidationError for #{description}, which no project or group can have" do
          expect { transpile_including(value) }
            .to raise_error(Gitlab::PolicyStore::ValidationError, /outside the range 1 to 9223372036854775807/)
        end
      end

      it "accepts an id at the widest a bigint holds" do
        expect(transpile_including("9223372036854775807"))
          .to include("input.project.id in {9223372036854775807}")
      end

      it "elides a string too long to be an id rather than echoing it", :aggregate_failures do
        expect { transpile_including("9" * 65) }
          .to raise_error(Gitlab::PolicyStore::ValidationError) { |error|
            expect(error.message.length).to be < 200
            expect(error.message).to end_with("...")
          }
      end

      it "names a container by its type, so nothing it holds is rendered" do
        expect { transpile_including({ "id" => [10**5_000] }) }
          .to raise_error(Gitlab::PolicyStore::ValidationError, /is not an id: Array/)
      end

      it "refuses an id too wide to render without rendering it", :aggregate_failures do
        expect { transpile_including(10**5_000) }
          .to raise_error(Gitlab::PolicyStore::ValidationError) { |error|
            expect(error.message.length).to be < 100
            expect(error.message).not_to include("0000")
          }
      end
    end

    context "with a criterion that is not a list of ids" do
      it "raises rather than compiling an inclusion that matches nothing" do
        expect { described_class.new({ "projects" => { "including" => "5" } }, policy_name: "P").transpile }
          .to raise_error(Gitlab::PolicyStore::ValidationError, /criterion that is not a list of ids: "5"/)
      end

      it "raises rather than widening a policy whose exclusion it cannot read" do
        expect { described_class.new({ "projects" => { "excluding" => { "id" => 5 } } }, policy_name: "P").transpile }
          .to raise_error(Gitlab::PolicyStore::ValidationError, /criterion that is not a list of ids: Hash/)
      end

      it "refuses a bare Integer without rendering it, however wide it is", :aggregate_failures do
        expect { described_class.new({ "projects" => { "including" => 10**5_000 } }, policy_name: "P").transpile }
          .to raise_error(Gitlab::PolicyStore::ValidationError) { |error|
            expect(error.message).to end_with("Integer")
            expect(error.message.length).to be < 100
          }
      end
    end

    context "with an id it cannot compile on the excluding side" do
      # An excluded id that is dropped rather than refused removes the whole
      # `scope_excluded` body, so the policy applies to what the author excluded.
      it "raises rather than widening the policy to the project it was told to exclude" do
        expect { transpile_excluding("1; injected") }
          .to raise_error(Gitlab::PolicyStore::ValidationError, /is not an id/)
      end

      it "keeps compiling an exclusion that names no id, since that is not a failed id" do
        expect(transpile_excluding({ "type" => "personal" })).to include("input.project.personal == true")
      end
    end

    # `security_policy_scope.json` requires `id` only for security attributes, so
    # `[{}]` is a valid entry everywhere else, and the root permits unknown keys.
    # These are the scopes where "the author declared a condition" and "the
    # condition names anything" come apart, and each expectation below is the
    # answer `Security::SecurityOrchestrationPolicies::PolicyScopeChecker` gives
    # for the same scope. Getting these wrong is not cosmetic: reading a declared
    # criterion as no criterion at all turns a policy that applies to nothing into
    # one that applies to every project.
    context "with a schema-valid scope that names no ids" do
      def applies_to_all?(rego)
        rego.include?("applies := true")
      end

      it "matches nothing when compliance_frameworks declares an entry with no id" do
        rego = described_class.new({ compliance_frameworks: [{}] }, policy_name: "P").transpile

        expect(applies_to_all?(rego)).to be(false)
        expect(rego).to include("framework_id in set()")
      end

      it "matches nothing when projects.including declares an entry with no id" do
        rego = described_class.new({ projects: { including: [{}] } }, policy_name: "P").transpile

        expect(applies_to_all?(rego)).to be(false)
        expect(rego).to include("input.project.id in set()")
      end

      it "matches nothing when groups.including declares an entry with no id" do
        rego = described_class.new({ groups: { including: [{}] } }, policy_name: "P").transpile

        expect(applies_to_all?(rego)).to be(false)
        expect(rego).to include("group_id in set()")
      end

      # The checker returns true here: an exclusion naming no project excludes
      # nothing, and an absent inclusion restricts nothing.
      it "applies everywhere when projects.excluding declares an entry with no id" do
        rego = described_class.new({ projects: { excluding: [{}] } }, policy_name: "P").transpile

        expect(rego).to include("included if { true }")
        expect(rego).not_to include("set()")
      end

      # An empty array is not a declared condition, for the checker or here.
      it "applies to all projects when compliance_frameworks is an empty array" do
        rego = described_class.new({ compliance_frameworks: [] }, policy_name: "P").transpile

        expect(applies_to_all?(rego)).to be(true)
      end

      # The root schema has no `additionalProperties: false`, so a misspelled key
      # validates. The checker sees no condition and applies the policy everywhere,
      # and matching that behaviour is deliberate rather than incidental.
      it "applies to all projects when the only key is one it does not recognize" do
        rego = described_class.new({ complience_frameworks: [{ id: 5 }] }, policy_name: "P").transpile

        expect(applies_to_all?(rego)).to be(true)
      end
    end

    # The policy-name schema (1..255 characters) permits quotes and newlines, and the
    # name is interpolated into a comment in generated source, where an unescaped
    # newline would end the comment and let the rest of the name parse as Rego. So
    # `to_json` is doing real work here; this guards against a refactor to plain
    # interpolation.
    context "with a name that needs escaping" do
      it "escapes the policy name in the generated Rego" do
        rego = described_class.new(nil, policy_name: %(A "quoted"\nname)).transpile

        expect(rego).to include('A \"quoted\"\nname')
      end
    end
  end

  describe "#scope_dimensions" do
    it "returns an empty array for an unscoped policy" do
      dimensions = described_class.new(nil, policy_name: "P").scope_dimensions

      expect(dimensions).to eq([])
    end

    it "emits a path once when both an inclusion and an exclusion reference it" do
      dimensions = described_class.new(
        { projects: { including: [{ id: 1 }], excluding: [{ id: 2 }] } }, policy_name: "P"
      ).scope_dimensions

      expect(dimensions).to eq(["project.id"])
    end

    it "includes a path for a declared inclusion that names no id" do
      dimensions = described_class.new({ compliance_frameworks: [{}] }, policy_name: "P").scope_dimensions

      expect(dimensions).to eq(["compliance_frameworks"])
    end

    it "omits a criterion that was not declared" do
      dimensions = described_class.new({ compliance_frameworks: [] }, policy_name: "P").scope_dimensions

      expect(dimensions).to eq([])
    end

    it "lists every dimension the compiled program reads, inclusion and exclusion alike" do
      dimensions = described_class.new(
        {
          compliance_frameworks: [{ id: 5 }],
          groups: { excluding: [{ id: 9 }] },
          business_unit: { including: [{ id: 1 }] },
          exposure: { excluding: [{ id: 2 }] },
          projects: { excluding: [{ type: "personal" }] }
        },
        policy_name: "P"
      ).scope_dimensions

      expect(dimensions).to contain_exactly(
        "compliance_frameworks", "groups", "security_attributes.business_unit",
        "security_attributes.exposure", "project.personal"
      )
    end
  end
end
