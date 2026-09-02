# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::PolicyStore::ScopeTranspiler do
  subject(:transpiler) { described_class.new(policy_scope, policy_name: policy_name) }

  let(:policy_scope) { {} }
  let(:policy_name) { "P" }

  def fixture_rego(name)
    File.read(File.expand_path("../../fixtures/scope/#{name}/policy.rego", __dir__))
  end

  def fixture_dimensions(name)
    JSON.parse(File.read(File.expand_path("../../fixtures/scope/#{name}/dimensions.json", __dir__)))
  end

  describe "#transpile" do
    subject(:rego) { transpiler.transpile }

    # Whole-string comparison against committed fixtures, rather than matching
    # fragments, because `scope_rego` is stored and evaluated as text. Its
    # whitespace and rule ordering are part of what we ship, and fragment
    # matching would let them drift unnoticed.
    context "with golden fixtures" do
      context "with no scope at all" do
        let(:policy_scope) { nil }
        let(:policy_name) { "Applies everywhere" }

        it "regenerates no_scope byte-for-byte" do
          expect(rego).to eq(fixture_rego("no_scope"))
          expect(transpiler.scope_dimensions).to eq(fixture_dimensions("no_scope"))
        end
      end

      context "with a compliance framework and an archived exclusion" do
        let(:policy_scope) do
          { compliance_frameworks: [{ id: 5 }], projects: { excluding: [{ type: "archived" }] } }
        end

        let(:policy_name) { "Scoped to compliance framework 5" }

        it "regenerates applies_framework byte-for-byte" do
          expect(rego).to eq(fixture_rego("applies_framework"))
          expect(transpiler.scope_dimensions).to eq(fixture_dimensions("applies_framework"))
        end
      end

      context "with groups and business impact under match_mode any" do
        let(:policy_scope) do
          { match_mode: "any", groups: { including: [{ id: 10 }] }, business_impact: { including: [{ id: 1 }] } }
        end

        let(:policy_name) { "Scoped to groups (any)" }

        it "regenerates groups_any byte-for-byte" do
          expect(rego).to eq(fixture_rego("groups_any"))
          expect(transpiler.scope_dimensions).to eq(fixture_dimensions("groups_any"))
        end
      end

      context "with an archived exclusion alone" do
        let(:policy_scope) { { projects: { excluding: [{ type: "archived" }] } } }
        let(:policy_name) { "Excluding archived projects" }

        it "regenerates excluded_archived byte-for-byte" do
          expect(rego).to eq(fixture_rego("excluded_archived"))
          expect(transpiler.scope_dimensions).to eq(fixture_dimensions("excluded_archived"))
        end
      end
    end

    context "with individual scope constructs" do
      context "with an include (all) and an exclude" do
        let(:policy_scope) do
          {
            match_mode: "all",
            compliance_frameworks: [{ id: 5 }],
            projects: { including: [{ id: 42 }, { id: 43 }], excluding: [{ id: 77 }, { type: "archived" }] }
          }
        end

        let(:policy_name) { "Block denied licenses" }

        it "emits a scoped block, ending in a total applies rule" do
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
      end

      context "with a compliance framework as the only dimension" do
        let(:policy_scope) { { compliance_frameworks: [{ id: 5 }] } }

        # The engine queries `data.gitlab.scope.applies` and nothing else, so any further
        # rule would be text nobody reads in a stored, length-capped column. An earlier
        # revision exposed a `results` set and `applicable`/`not_applicable`/`applicability`
        # aggregates over it, which only pay off when several policies' programs answer in
        # one query, and these rule names are not namespaced per policy, so co-loading them
        # into one engine ORs them into each other instead.
        it "exposes no rule beyond applies and the two it is derived from" do
          rule_names = rego.scan(/^(?:default )?(\w+)(?= if | := )/).flatten.uniq

          expect(rule_names).to contain_exactly("excluded", "included", "applies")
        end
      end

      context "with two dimensions under match_mode any" do
        let(:policy_scope) do
          { match_mode: "any", groups: { including: [{ id: 10 }] }, business_impact: { including: [{ id: 1 }] } }
        end

        it "emits one included body per dimension" do
          expect(rego.scan("included if {").length).to eq(2)
          expect(rego).to include("some group_id in input.groups")
          expect(rego).to include("some business_impact_id in input.security_attributes.business_impact")
        end
      end

      context "with an empty scope" do
        let(:policy_scope) { {} }
        let(:policy_name) { "Unscoped" }

        it "emits an unconditional applies rule" do
          expect(rego).to include('# policy "Unscoped"')
          expect(rego).to include("no policy_scope: applies to all projects")
          expect(rego).to include("applies := true")
          expect(rego).not_to include("default applies")
        end
      end

      context "with only excludes present" do
        let(:policy_scope) { { projects: { excluding: [{ id: 9 }] } } }

        it "emits a constant included rule" do
          expect(rego).to include("included if { true }")
        end
      end
    end

    context "with input coercion" do
      context "with bare integer ids" do
        let(:policy_scope) { { compliance_frameworks: [5] } }

        it "compiles them the same as { id: n } hashes" do
          from_hashes = described_class.new({ compliance_frameworks: [{ id: 5 }] },
            policy_name: policy_name).transpile

          expect(rego).to eq(from_hashes)
        end
      end

      context "with ids repeated and out of order" do
        let(:policy_scope) { { projects: { including: [{ id: 5 }, { id: 3 }, { id: 5 }] } } }

        it "deduplicates and sorts them, so authoring order does not change the stored text" do
          expect(rego).to include("input.project.id in {3, 5}")
        end
      end

      context "with string keys, as jsonb round-trips them" do
        let(:policy_scope) { { "groups" => { "including" => [{ "id" => 10 }] } } }

        it "compiles them the same as symbol keys" do
          with_symbols = described_class.new({ groups: { including: [{ id: 10 }] } },
            policy_name: policy_name).transpile

          expect(rego).to eq(with_symbols)
        end
      end

      context "with symbol values" do
        let(:policy_scope) { { match_mode: :any, groups: { including: [{ id: 10 }] } } }

        it "compiles them the same as their JSON round trip" do
          round_tripped = JSON.parse(JSON.generate(policy_scope))

          expect(rego).to eq(described_class.new(round_tripped, policy_name: policy_name).transpile)
        end
      end

      context "with a symbol project type in an excluding entry" do
        let(:policy_scope) { { projects: { excluding: [{ type: :personal }] } } }

        it "honours it" do
          expect(rego).to include("personal")
        end
      end

      context "with ids delivered as strings, as a form-encoded request sends them" do
        let(:policy_scope) { { "compliance_frameworks" => [{ "id" => "5" }] } }

        it "compiles them the same as integers" do
          from_integers = described_class.new({ compliance_frameworks: [{ id: 5 }] },
            policy_name: policy_name).transpile

          expect(rego).to eq(from_integers)
        end
      end

      context "with bare string ids alongside { id: \"n\" } hashes" do
        let(:policy_scope) { { "projects" => { "including" => ["5", { "id" => "3" }] } } }

        it "accepts both" do
          expect(rego).to include("input.project.id in {3, 5}")
        end
      end

      context "with an entry that declares a condition without naming an id" do
        let(:policy_scope) { { "projects" => { "including" => [{}] } } }

        it "keeps the entry" do
          expect(rego).to include("input.project.id in set()")
        end
      end
    end

    context "with a projects.including criterion" do
      context "with a padded id" do
        let(:policy_scope) { { "projects" => { "including" => ["007"] } } }

        it "accepts it, since the padding does not change which id it names" do
          expect(rego).to include("input.project.id in {7}")
        end
      end

      context "with an id at the widest a bigint holds" do
        let(:policy_scope) { { "projects" => { "including" => ["9223372036854775807"] } } }

        it "accepts it" do
          expect(rego).to include("input.project.id in {9223372036854775807}")
        end
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
        context "with #{description}" do
          let(:policy_scope) { { "projects" => { "including" => [value] } } }

          it "raises ValidationError, rather than silently dropping it" do
            expect { rego }.to raise_error(Gitlab::PolicyStore::ValidationError, /is not an id/)
          end
        end
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
        context "with #{description}" do
          let(:policy_scope) { { "projects" => { "including" => [value] } } }

          it "raises ValidationError, which no project or group can have" do
            expect { rego }
              .to raise_error(Gitlab::PolicyStore::ValidationError, /outside the range 1 to 9223372036854775807/)
          end
        end
      end

      context "with bytes that are not valid UTF-8" do
        let(:policy_scope) { { "projects" => { "including" => [(+"\xFF5").force_encoding("UTF-8")] } } }

        it "raises ValidationError, not an encoding error" do
          expect { rego }
            .to raise_error(Gitlab::PolicyStore::ValidationError, /text that is not valid UTF-8/)
        end
      end

      context "with an id whose encoding is what refused it, since the bytes can read as one" do
        let(:policy_scope) { { "projects" => { "including" => ["5".encode("UTF-32BE")] } } }

        it "names the encoding" do
          expect { rego }
            .to raise_error(Gitlab::PolicyStore::ValidationError, /text encoded as UTF-32BE/)
        end
      end

      context "with one valid id and one that is not an id" do
        let(:policy_scope) { { "projects" => { "including" => [3, "1; injected"] } } }

        it "names the offending value, so the caller can find it" do
          expect { rego }
            .to raise_error(Gitlab::PolicyStore::ValidationError, /"1; injected"/)
        end
      end

      context "with a string too long to be an id" do
        let(:policy_scope) { { "projects" => { "including" => ["9" * 65] } } }

        it "elides it rather than echoing it", :aggregate_failures do
          expect { rego }
            .to raise_error(Gitlab::PolicyStore::ValidationError) { |error|
              expect(error.message.length).to be < 200
              expect(error.message).to end_with("...")
            }
        end
      end

      context "with a container where an id belongs" do
        let(:policy_scope) { { "projects" => { "including" => [{ "id" => [10**5_000] }] } } }

        it "names it by its type, so nothing it holds is rendered" do
          expect { rego }
            .to raise_error(Gitlab::PolicyStore::ValidationError, /is not an id: Array/)
        end
      end

      context "with an id too wide to render" do
        let(:policy_scope) { { "projects" => { "including" => [10**5_000] } } }

        it "refuses it without rendering it", :aggregate_failures do
          expect { rego }
            .to raise_error(Gitlab::PolicyStore::ValidationError) { |error|
              expect(error.message.length).to be < 100
              expect(error.message).not_to include("0000")
            }
        end
      end
    end

    context "with a value that is not an id outside projects" do
      let(:policy_scope) { { "groups" => { "including" => ["1; injected"] } } }

      it "refuses it wherever it is authored" do
        expect { rego }.to raise_error(Gitlab::PolicyStore::ValidationError, /is not an id/)
      end
    end

    context "with a criterion that is not a list of ids" do
      context "with a string where an inclusion list belongs" do
        let(:policy_scope) { { "projects" => { "including" => "5" } } }

        it "raises rather than compiling an inclusion that matches nothing" do
          expect { rego }
            .to raise_error(Gitlab::PolicyStore::ValidationError, /criterion that is not a list of ids: "5"/)
        end
      end

      context "with a hash where an exclusion list belongs" do
        let(:policy_scope) { { "projects" => { "excluding" => { "id" => 5 } } } }

        it "raises rather than widening a policy whose exclusion it cannot read" do
          expect { rego }
            .to raise_error(Gitlab::PolicyStore::ValidationError, /criterion that is not a list of ids: Hash/)
        end
      end

      context "with a bare Integer where an inclusion list belongs" do
        let(:policy_scope) { { "projects" => { "including" => 10**5_000 } } }

        it "refuses it without rendering it, however wide it is", :aggregate_failures do
          expect { rego }
            .to raise_error(Gitlab::PolicyStore::ValidationError) { |error|
              expect(error.message).to end_with("Integer")
              expect(error.message.length).to be < 100
            }
        end
      end
    end

    context "with a projects.excluding criterion" do
      context "with an entry whose id is null" do
        let(:policy_scope) { { "projects" => { "excluding" => [nil, { "id" => 7 }] } } }

        it "keeps the entry, since a null names no id either" do
          expect(rego).to include("input.project.id in {7}")
        end
      end

      # An excluded id that is dropped rather than refused removes the whole
      # `scope_excluded` body, so the policy applies to what the author excluded.
      context "with an id it cannot compile" do
        let(:policy_scope) { { "projects" => { "excluding" => ["1; injected"] } } }

        it "raises rather than widening the policy to the project it was told to exclude" do
          expect { rego }.to raise_error(Gitlab::PolicyStore::ValidationError, /is not an id/)
        end
      end

      context "with an exclusion that names no id" do
        let(:policy_scope) { { "projects" => { "excluding" => [{ "type" => "personal" }] } } }

        it "keeps compiling it, since that is not a failed id" do
          expect(rego).to include("input.project.personal == true")
        end
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

      context "when compliance_frameworks declares an entry with no id" do
        let(:policy_scope) { { compliance_frameworks: [{}] } }

        it "matches nothing" do
          expect(applies_to_all?(rego)).to be(false)
          expect(rego).to include("framework_id in set()")
        end
      end

      context "when projects.including declares an entry with no id" do
        let(:policy_scope) { { projects: { including: [{}] } } }

        it "matches nothing" do
          expect(applies_to_all?(rego)).to be(false)
          expect(rego).to include("input.project.id in set()")
        end
      end

      context "when groups.including declares an entry with no id" do
        let(:policy_scope) { { groups: { including: [{}] } } }

        it "matches nothing" do
          expect(applies_to_all?(rego)).to be(false)
          expect(rego).to include("group_id in set()")
        end
      end

      # The checker returns true here: an exclusion naming no project excludes
      # nothing, and an absent inclusion restricts nothing.
      context "when projects.excluding declares an entry with no id" do
        let(:policy_scope) { { projects: { excluding: [{}] } } }

        it "applies everywhere" do
          expect(rego).to include("included if { true }")
          expect(rego).not_to include("set()")
        end
      end

      # An empty array is not a declared condition, for the checker or here.
      context "when compliance_frameworks is an empty array" do
        let(:policy_scope) { { compliance_frameworks: [] } }

        it "applies to all projects" do
          expect(applies_to_all?(rego)).to be(true)
        end
      end

      # The root schema has no `additionalProperties: false`, so a misspelled key
      # validates. The checker sees no condition and applies the policy everywhere,
      # and matching that behaviour is deliberate rather than incidental.
      context "when the only key is one it does not recognize" do
        let(:policy_scope) { { complience_frameworks: [{ id: 5 }] } }

        it "applies to all projects" do
          expect(applies_to_all?(rego)).to be(true)
        end
      end
    end

    # The policy-name schema (1..255 characters) permits quotes and newlines, and the
    # name is interpolated into a comment in generated source, where an unescaped
    # newline would end the comment and let the rest of the name parse as Rego. So
    # `to_json` is doing real work here; this guards against a refactor to plain
    # interpolation.
    context "with a name that needs escaping" do
      let(:policy_scope) { nil }
      let(:policy_name) { %(A "quoted"\nname) }

      it "escapes the policy name in the generated Rego" do
        expect(rego).to include('A \"quoted\"\nname')
      end
    end
  end

  describe "#scope_dimensions" do
    subject(:dimensions) { transpiler.scope_dimensions }

    context "with an unscoped policy" do
      let(:policy_scope) { nil }

      it "returns an empty array" do
        expect(dimensions).to eq([])
      end
    end

    context "with both an inclusion and an exclusion referencing the same path" do
      let(:policy_scope) { { projects: { including: [{ id: 1 }], excluding: [{ id: 2 }] } } }

      it "emits the path once" do
        expect(dimensions).to eq(["project.id"])
      end
    end

    context "with a declared inclusion that names no id" do
      let(:policy_scope) { { compliance_frameworks: [{}] } }

      it "includes a path for it" do
        expect(dimensions).to eq(["compliance_frameworks"])
      end
    end

    context "with a criterion that was not declared" do
      let(:policy_scope) { { compliance_frameworks: [] } }

      it "omits it" do
        expect(dimensions).to eq([])
      end
    end

    context "with inclusions and exclusions across every dimension" do
      let(:policy_scope) do
        {
          compliance_frameworks: [{ id: 5 }],
          groups: { excluding: [{ id: 9 }] },
          business_unit: { including: [{ id: 1 }] },
          exposure: { excluding: [{ id: 2 }] },
          projects: { excluding: [{ type: "personal" }] }
        }
      end

      it "lists every dimension the compiled program reads" do
        expect(dimensions).to contain_exactly(
          "compliance_frameworks", "groups", "security_attributes.business_unit",
          "security_attributes.exposure", "project.personal"
        )
      end
    end
  end
end
