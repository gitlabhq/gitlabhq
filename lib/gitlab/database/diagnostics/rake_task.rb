# frozen_string_literal: true

module Gitlab
  module Database
    module Diagnostics
      # Shared body of gitlab:db:diagnostics and its generated per-check tasks.
      module RakeTask
        module_function

        def run(args, check_name: nil)
          # Rake splits `[main,ci]` on commas, so later names land in `extras`.
          requested = [args[:database_names], *args.extras].compact.map(&:strip).reject(&:empty?)

          valid_names = Gitlab::Database.database_base_models.keys
          unknown = requested - valid_names
          abort("Unknown database(s): #{unknown.join(', ')}. Valid: #{valid_names.join(', ')}.") if unknown.any?

          # Skip shared connections, or a single-cluster install reports the same database repeatedly.
          database_names = requested.presence || Gitlab::Database.database_base_models
            .reject { |_, model| Gitlab::Database.db_config_share_with(model.connection_db_config) }
            .keys

          check_names = Array(check_name).presence
          result = Console.run(database_names: database_names, check_names: check_names)

          abort('Database diagnostics found errors. Review the output above.') if result == Findings::ERROR
        end
      end
    end
  end
end
