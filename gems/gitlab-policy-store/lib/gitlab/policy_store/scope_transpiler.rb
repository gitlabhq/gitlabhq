# frozen_string_literal: true

require "json"

module Gitlab
  module PolicyStore
    # Compiles a policy's authored `policy_scope`, a plain jsonb hash, into
    # `scope_rego` text in the `package gitlab.scope` namespace.
    class ScopeTranspiler
      # Rego indents with tabs, written here as `\t` escapes so the squiggly
      # heredoc's dedent cannot absorb them.
      SCOPE_PRELUDE = <<~REGO.chomp
        package gitlab.scope

        applicable := [result.policy | some result in results; result.applies]

        not_applicable := [result.policy | some result in results; not result.applies]

        applicability := {
        \t"applicable": applicable,
        \t"not_applicable": not_applicable,
        \t"results": [result | some result in results],
        }
      REGO

      # Rego loop variables must be unique within a single AND body (match_mode
      # "all"), so each dimension carries its own.
      ATTRIBUTE_DIMENSIONS = [
        { key: :business_impact, field: "business_impact", loop_variable: "business_impact_id" },
        { key: :application,     field: "application",     loop_variable: "application_id" },
        { key: :business_unit,   field: "business_unit",   loop_variable: "business_unit_id" },
        { key: :exposure,        field: "exposure",        loop_variable: "exposure_id" }
      ].freeze

      # A nil or empty `policy_scope` is authored intent, not missing data: it means the
      # policy applies everywhere. `policy_name` is emitted into the generated program.
      def initialize(policy_scope, policy_name:)
        @policy_scope = policy_scope
        @policy_name = policy_name.to_s
      end

      def transpile
        "#{SCOPE_PRELUDE}\n\n#{scope_block}\n"
      end

      private

      attr_reader :policy_scope, :policy_name

      def scope_block
        return unscoped_block if unscoped?

        statements = [header]

        statements << "default #{excluded_rule} := false"
        excluded_conditions.each do |condition|
          statements << "#{excluded_rule} if {\n#{indent(condition)}\n}"
        end

        statements << "default #{included_rule} := false"
        statements.concat(included_statements)

        statements << "default #{applies_rule} := false"
        statements << "#{applies_rule} if {\n\tnot #{excluded_rule}\n\t#{included_rule}\n}"
        statements << results_statement

        statements.join("\n\n")
      end

      def unscoped_block
        <<~REGO.chomp
          #{header}
          results contains {
          \t"policy": #{policy_name.to_json},
          \t"applies": true,
          \t"reason": "no policy_scope: applies to all projects",
          }
        REGO
      end

      def results_statement
        <<~REGO.chomp
          results contains {
          \t"policy": #{policy_name.to_json},
          \t"applies": #{applies_rule},
          \t"reason": sprintf("excluded=%v, included=%v (match_mode=#{match_mode})", [#{excluded_rule}, #{included_rule}]),
          }
        REGO
      end

      def included_statements
        conditions = included_conditions
        return ["#{included_rule} if { true }"] if conditions.empty?
        return ["#{included_rule} if {\n#{indent(conditions.flatten)}\n}"] if match_mode == "all"

        conditions.map { |condition| "#{included_rule} if {\n#{indent(condition)}\n}" }
      end

      def header
        "# policy #{policy_name.to_json}"
      end

      def excluded_rule
        "scope_excluded"
      end

      def included_rule
        "scope_included"
      end

      def applies_rule
        "scope_applies"
      end

      def included_conditions
        conditions = []

        if emit?(compliance_frameworks, :including)
          conditions << ["some framework_id in input.compliance_frameworks",
            "framework_id in #{rego_set(compliance_frameworks[:ids])}"]
        end

        included_projects = projects[:including]

        if emit?(included_projects, :including)
          conditions << ["input.project.id in #{rego_set(included_projects[:ids])}"]
        end

        included_groups = groups[:including]

        if emit?(included_groups, :including)
          conditions << ["some group_id in input.groups", "group_id in #{rego_set(included_groups[:ids])}"]
        end

        conditions.concat(attribute_conditions(:including))
      end

      def excluded_conditions
        conditions = []

        excluded_projects = projects[:excluding]

        if emit?(excluded_projects, :excluding)
          conditions << ["input.project.id in #{rego_set(excluded_projects[:ids])}"]
        end

        conditions << ["input.project.personal == true"] if projects[:exclude_personal]
        conditions << ["input.project.archived == true"] if projects[:exclude_archived]

        excluded_groups = groups[:excluding]

        if emit?(excluded_groups, :excluding)
          conditions << ["some group_id in input.groups", "group_id in #{rego_set(excluded_groups[:ids])}"]
        end

        conditions.concat(attribute_conditions(:excluding))
      end

      def attribute_conditions(direction)
        ATTRIBUTE_DIMENSIONS.filter_map do |attribute|
          criterion = dimensions[attribute[:key]][direction]
          next unless emit?(criterion, direction)

          loop_variable = attribute[:loop_variable]

          [
            "some #{loop_variable} in input.security_attributes.#{attribute[:field]}",
            "#{loop_variable} in #{rego_set(criterion[:ids])}"
          ]
        end
      end

      # A declared inclusion is emitted even with no ids, because it has to match
      # nothing. A declared exclusion in the same state excludes nothing, so
      # omitting it says the same thing in less text.
      def emit?(criterion, direction)
        direction == :including ? criterion[:declared] : criterion[:ids].any?
      end

      # `set()` is Rego's empty set literal, and membership against it is always
      # false. `{}` cannot be used for this: it is an empty object.
      def rego_set(member_ids)
        return "set()" if member_ids.empty?

        "{#{member_ids.uniq.sort.join(', ')}}"
      end

      def indent(lines)
        lines.map { |line| "\t#{line}" }.join("\n")
      end

      # Tests what the author declared, not what it resolves to, so that a criterion
      # yielding no ids still counts as a scope. The personal and archived flags need
      # no test of their own: either one implies `projects.excluding` was declared.
      def unscoped?
        return true unless authored?
        return false if dimensions.each_value.any? { |dimension| declared_dimension?(dimension) }

        !compliance_frameworks[:declared] &&
          !projects[:including][:declared] &&
          !projects[:excluding][:declared]
      end

      def declared_dimension?(dimension)
        dimension[:including][:declared] || dimension[:excluding][:declared]
      end

      def authored?
        policy_scope.is_a?(Hash) && !policy_scope.empty?
      end

      def source
        @source ||= authored? ? JsonValue.deep_stringify(policy_scope) : {}
      end

      def match_mode
        source["match_mode"] == "any" ? "any" : "all"
      end

      def compliance_frameworks
        @compliance_frameworks ||= build_criterion(source["compliance_frameworks"])
      end

      def projects
        @projects ||= {
          including: build_criterion(raw_projects["including"]),
          excluding: build_criterion(raw_projects["excluding"]),
          exclude_personal: excludes_type?("personal"),
          exclude_archived: excludes_type?("archived")
        }
      end

      def groups
        dimensions[:groups]
      end

      def dimensions
        @dimensions ||= {
          groups: build_dimension(source["groups"]),
          business_impact: build_dimension(source["business_impact"]),
          application: build_dimension(source["application"]),
          business_unit: build_dimension(source["business_unit"]),
          exposure: build_dimension(source["exposure"])
        }
      end

      def raw_projects
        @raw_projects ||= source["projects"].is_a?(Hash) ? source["projects"] : {}
      end

      def excluded_project_entries
        @excluded_project_entries ||= raw_projects["excluding"].is_a?(Array) ? raw_projects["excluding"] : []
      end

      def excludes_type?(type)
        excluded_project_entries.any? { |item| item.is_a?(Hash) && item["type"] == type }
      end

      def build_dimension(raw_dimension)
        source = raw_dimension.is_a?(Hash) ? raw_dimension : {}
        { including: build_criterion(source["including"]), excluding: build_criterion(source["excluding"]) }
      end

      # Declaring a criterion and naming an id are tracked separately because the two
      # come apart: `[{}]` declares a condition that carries no id. Collapsing them
      # would turn a policy that applies to nothing into one that applies to every
      # project.
      def build_criterion(raw_value)
        { declared: declared?(raw_value), ids: ids_from(raw_value) }
      end

      # An absent key and an empty collection both read as undeclared.
      def declared?(raw_value)
        return false if raw_value.nil?
        return !raw_value.empty? if raw_value.respond_to?(:empty?)

        true
      end

      # Anything that is not an integer id is dropped rather than interpolated, so an
      # unexpected value cannot reach the generated program.
      def ids_from(value)
        return [] unless value.is_a?(Array)

        value.filter_map do |item|
          if item.is_a?(Integer)
            item
          elsif item.is_a?(Hash) && item["id"].is_a?(Integer)
            item["id"]
          end
        end
      end
    end
  end
end
