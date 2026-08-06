# frozen_string_literal: true

module Gitlab
  module Cd
    module Driver
      # Assembles a single AutoFlow deploy program from the orchestration engine
      # and one or more deploy driver deploy() fragments.
      #
      # Each driver ships a module-level `def deploy():` that registers its step
      # handlers. To let several drivers coexist in one program, every driver's
      # deploy() is renamed to a gem-unique identifier and invoked at load, after
      # the orchestrator's main.star is prepended.
      #
      # A driver fragment must therefore define `deploy()` and must not bind
      # anything at module level that the engine already owns (see
      # ENGINE_GLOBALS): the parts are concatenated into one Starlark module, and
      # Starlark rejects rebinding a global. assemble enforces both.
      module Orchestration
        MAIN_PROGRAM_PATH = File.expand_path("../../../../scripts/main.star", __dir__)

        DEPLOY_DEF = /^def deploy\(/

        # The names scripts/main.star binds at module level. Hardcoded rather than
        # parsed on every assemble; a spec pins it to main.star so the two cannot
        # drift apart unnoticed.
        ENGINE_GLOBALS = %w[
          gitlab_function_run
          event_emit
          gl_run
          _require
          _STEPS
          _STAGE_TYPE
          _emit
          _fail_step
          _VALIDATORS
          register
          _wait
          _leaf_steps
          _step_environment
          _run_step
          _validator_steps
          _validate_flow
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

        # driver_scripts - Hash of { gem_name (String) => deploy.star source (String) }
        # Returns the combined program as an ASCII-8BIT string.
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

        # Escape a gem name into a safe, reversible Starlark identifier. Existing
        # underscores are doubled first, so every remaining single "_" in the
        # output unambiguously marks an escape sequence.
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

        # The names a Starlark fragment binds at module level.
        def fragment_globals(script)
          script.each_line.flat_map do |line|
            load_match = line.match(FRAGMENT_LOAD)
            next load_bindings(load_match[:args]) if load_match

            binding_match = line.match(FRAGMENT_DEF) || line.match(FRAGMENT_ASSIGN)
            binding_match ? [binding_match[:name]] : []
          end
        end

        # The names a load() binds: every argument after the module name, taking
        # the alias where one is given.
        def load_bindings(args)
          args.scan(LOAD_BINDING).drop(1).map { |alias_name, symbol| alias_name || symbol }
        end
      end
    end
  end
end
