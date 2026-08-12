# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::PolicyStore::ScopeTranspiler do
  def fixture_rego(name)
    File.read(File.expand_path("../../fixtures/scope/#{name}/policy.rego", __dir__))
  end

  describe ".transpile" do
    # Whole-string comparison against committed fixtures, rather than matching
    # fragments, because `scope_rego` is stored and evaluated as text. Its
    # whitespace and rule ordering are part of what we ship, and fragment
    # matching would let them drift unnoticed.
    context "with golden fixtures" do
      it "regenerates no_scope byte-for-byte" do
        rego = described_class.new(nil, policy_name: "Applies everywhere").transpile

        expect(rego).to eq(fixture_rego("no_scope"))
      end

      it "regenerates applies_framework byte-for-byte" do
        rego = described_class.new(
          { compliance_frameworks: [{ id: 5 }], projects: { excluding: [{ type: "archived" }] } },
          policy_name: "Scoped to compliance framework 5"
        ).transpile

        expect(rego).to eq(fixture_rego("applies_framework"))
      end

      it "regenerates groups_any byte-for-byte" do
        rego = described_class.new(
          { match_mode: "any", groups: { including: [{ id: 10 }] }, business_impact: { including: [{ id: 1 }] } },
          policy_name: "Scoped to groups (any)"
        ).transpile

        expect(rego).to eq(fixture_rego("groups_any"))
      end

      it "regenerates excluded_archived byte-for-byte" do
        rego = described_class.new(
          { projects: { excluding: [{ type: "archived" }] } },
          policy_name: "Excluding archived projects"
        ).transpile

        expect(rego).to eq(fixture_rego("excluded_archived"))
      end
    end

    context "with individual scope constructs" do
      it "emits the prelude and a scoped block with include (all) + exclude" do
        rego = described_class.new(
          {
            match_mode: "all",
            compliance_frameworks: [{ id: 5 }],
            projects: { including: [{ id: 42 }, { id: 43 }], excluding: [{ id: 77 }, { type: "archived" }] }
          },
          policy_name: "Block denied licenses"
        ).transpile

        expect(rego).to include("package gitlab.scope")
        expect(rego).to include('# policy "Block denied licenses"')
        expect(rego).to include("default scope_excluded := false")
        expect(rego).to include("input.project.id in {77}")
        expect(rego).to include("input.project.archived == true")
        expect(rego).to include("some framework_id in input.compliance_frameworks")
        expect(rego).to include("framework_id in {5}")
        expect(rego).to include("input.project.id in {42, 43}")
        expect(rego).to include("not scope_excluded")
        reason = 'sprintf("excluded=%v, included=%v (match_mode=all)", [scope_excluded, scope_included])'
        expect(rego).to include(reason)
      end

      it "emits one included body per dimension for match_mode any" do
        rego = described_class.new(
          { match_mode: "any", groups: { including: [{ id: 10 }] }, business_impact: { including: [{ id: 1 }] } },
          policy_name: "P"
        ).transpile

        expect(rego.scan("scope_included if {").length).to eq(2)
        expect(rego).to include("some group_id in input.groups")
        expect(rego).to include("some business_impact_id in input.security_attributes.business_impact")
      end

      it "emits applies:true for a no-scope (empty) policy" do
        rego = described_class.new({}, policy_name: "Unscoped").transpile

        expect(rego).to include('"policy": "Unscoped"')
        expect(rego).to include('"applies": true')
        expect(rego).to include("no policy_scope: applies to all projects")
        expect(rego).not_to include("scope_applies")
      end

      it "emits a constant included rule when only excludes are present" do
        rego = described_class.new(
          { projects: { excluding: [{ id: 9 }] } },
          policy_name: "P"
        ).transpile

        expect(rego).to include("scope_included if { true }")
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
        rego.include?('"applies": true')
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

        expect(rego).to include("scope_included if { true }")
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

    # The policy-name schema (1..255 characters) permits quotes and newlines, and
    # the name is interpolated into generated source, so `to_json` is doing real
    # work here. Guards against a future refactor to plain interpolation.
    context "with a name that needs escaping" do
      it "escapes the policy name in the generated Rego" do
        rego = described_class.new(nil, policy_name: %(A "quoted"\nname)).transpile

        expect(rego).to include('A \"quoted\"\nname')
      end
    end
  end
end
