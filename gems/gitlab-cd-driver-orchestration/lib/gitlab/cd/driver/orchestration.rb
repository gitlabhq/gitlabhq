# frozen_string_literal: true

module Gitlab
  module Cd
    module Driver
      # Assembles a single AutoFlow deploy program from the orchestration engine and
      # one or more driver deploy() fragments. Each driver ships a module-level `def
      # deploy():` that registers its step handlers; it is renamed to a gem-unique
      # identifier and invoked at load, so several drivers can coexist in one module.
      module Orchestration
        MAIN_PROGRAM_PATH = File.expand_path("../../../../scripts/main.star", __dir__)

        DEPLOY_DEF = /^def deploy\(/

        # Hardcoded rather than parsed out of main.star on every assemble; a spec pins
        # the two together so they cannot drift apart unnoticed.
        ENGINE_GLOBALS = %w[
          gitlab_function_run
          call_api
          post_value
          evaluate
          ALLOW
          DENY
          REQUIRE_APPROVAL
          get_object
          gl_run
          _require
          _STEPS
          _STAGE_TYPE
          _APPROVAL_TYPE
          _TOPIC
          _ACCEPTED
          _destination
          _problem
          _build_emitter
          failure
          _emit_step_failed
          _report_failure
          _service_reporter
          _build_asker
          _FLAGS
          _feature_flags
          _build_gate
          _ACTION_TRIGGERS
          register
          _WAIT_TYPE
          _wait
          _check_step_shape
          _check_flow_document
          _shape_failure_data
          _step_environment
          _rollout_resource
          _step_resource
          _gated_by
          _plan
          _owned_steps
          _validate_flow
          _bind_handlers
          _step_boundary
          _run_step
          _check_hitl
          main
        ].freeze

        # Module-level bindings, matched at column 0 because anything indented is
        # local to a function and cannot collide.
        FRAGMENT_DEF = /^def\s+(?<name>\w+)\s*\(/
        FRAGMENT_ASSIGN = /^(?<name>\w+)\s*=[^=]/
        FRAGMENT_LOAD = /^load\((?<args>[^)]*)\)/

        # A load() argument: `alias = "symbol"` binds alias, a bare "symbol" binds
        # symbol.
        LOAD_BINDING = /(?:(?<alias>\w+)\s*=\s*)?"(?<symbol>[^"]*)"/

        module_function

        # driver_scripts - { gem_name => deploy.star source }
        def assemble(driver_scripts:)
          parts = [main_program]

          driver_scripts.each do |gem_name, script|
            check_engine_globals(gem_name, script)

            identifier = gem_name_to_identifier(gem_name)
            parts << rename_deploy(script, identifier)
            parts << "#{identifier}_deploy()\n"
          end

          parts.join("\n").b
        end

        # Escapes a gem name into a reversible Starlark identifier. Underscores are
        # doubled first, so every remaining single "_" marks an escape sequence.
        def gem_name_to_identifier(name)
          out = name.gsub("_", "__")
          out = out.gsub("-", "_d")
          out = out.gsub(".", "_p")
          out = "_#{out}" if out.match?(/\A[0-9]/)
          out
        end

        def main_program
          File.read(MAIN_PROGRAM_PATH)
        end

        def rename_deploy(script, identifier)
          raise ArgumentError, "driver script has no module-level `def deploy(`" unless script.match?(DEPLOY_DEF)

          script.sub(DEPLOY_DEF, "def #{identifier}_deploy(")
        end

        # Rejects a fragment that rebinds one of the engine's globals. Without this
        # the collision surfaces as a Starlark load failure inside kas at rollout
        # time, pointing at the concatenated program rather than at the fragment.
        def check_engine_globals(gem_name, script)
          collisions = (fragment_globals(script) & ENGINE_GLOBALS).uniq.sort
          return if collisions.empty?

          raise ArgumentError,
            "#{gem_name} redeclares globals the orchestration engine owns: #{collisions.join(', ')}. " \
              "Starlark rejects rebinding a global, so the assembled program would fail to load. " \
              "Remove them from the fragment and use the engine's."
        end

        def fragment_globals(script)
          script.each_line.flat_map do |line|
            load_match = line.match(FRAGMENT_LOAD)
            next load_bindings(load_match[:args]) if load_match

            binding_match = line.match(FRAGMENT_DEF) || line.match(FRAGMENT_ASSIGN)
            binding_match ? [binding_match[:name]] : []
          end
        end

        # Every argument after the module name, taking the alias where one is given.
        def load_bindings(args)
          args.scan(LOAD_BINDING).drop(1).map { |alias_name, symbol| alias_name || symbol }
        end
      end
    end
  end
end
