# frozen_string_literal: true

module Keeps
  module Prompts
    class RemoveObsoleteMigrations
      attr_reader :logger

      def initialize(logger)
        @logger = logger
      end

      def fetch(migration_class_name, migration_snake_case_name, file)
        if file.end_with?('_spec.rb')
          prompt_rspec(migration_class_name, migration_snake_case_name, file)
        elsif file.end_with?('.rb')
          prompt_ruby(migration_class_name, migration_snake_case_name, file)
        elsif file.end_with?('.md')
          prompt_markdown(migration_class_name, migration_snake_case_name, file)
        else
          logger.puts("Unexpected file extension in #{file} referencing migration #{migration_class_name}. Skipping.")
          nil
        end
      end

      private

      def prompt_shared(migration_class_name, migration_snake_case_name, file)
        <<~MARKDOWN
          Your job is to remove references to obsolete Advanced Search migrations from code. An obsolete migration is one that has been completed on all GitLab instances and is no longer needed.

          The migration class is called `#{migration_class_name}` and its snake_case name is `#{migration_snake_case_name}`.

          The code below is in a file named `#{file}` and may contain references to this obsolete migration. It's possible this code does not contain explicit references to the migration. In that case make no changes.

          **CRITICAL: Understanding `migration_has_finished?` checks**

          The most important pattern to handle is `::Elastic::DataMigrationService.migration_has_finished?(:#{migration_snake_case_name})`.

          When a migration is marked as obsolete, this check ALWAYS returns `true`. This creates opportunities for significant code simplification by removing dead code branches.

          Once you are done with the changes, make sure to run rubocop as well and reformat the code. Also remove any dead code and unreachable code that you see after the refactoring.
        MARKDOWN
      end

      def prompt_ruby(migration_class_name, migration_snake_case_name, file)
        <<~MARKDOWN
          #{prompt_shared(migration_class_name, migration_snake_case_name, file)}

          ## Ruby Code Migration Reference Removal Guidelines

          ### Pattern 1: Simple conditional - keep the if branch

          When you see:
          ```ruby
          if ::Elastic::DataMigrationService.migration_has_finished?(:#{migration_snake_case_name})
            # new code path
          else
            # old code path
          end
          ```

          Since the migration is obsolete, the check always returns `true`, so simplify to:
          ```ruby
          # new code path
          ```

          The else branch is dead code and should be completely removed.

          ### Pattern 2: Early return pattern - simplify to unconditional return

          When you see:
          ```ruby
          return if ::Elastic::DataMigrationService.migration_has_finished?(:#{migration_snake_case_name})
          # code that runs when migration not finished
          ```

          Since the check always returns `true`, simplify to:
          ```ruby
          return
          ```

          Any code after this return is now unreachable and should be removed.

          ### Pattern 3: Negated check - remove entire block

          When you see:
          ```ruby
          if !::Elastic::DataMigrationService.migration_has_finished?(:#{migration_snake_case_name})
            # code when migration not finished
          end
          ```

          Since the check returns `true`, the negation is `false`, and this block never executes. Remove the entire if block.

          ### Pattern 4: Unless pattern - remove entire block

          When you see:
          ```ruby
          unless ::Elastic::DataMigrationService.migration_has_finished?(:#{migration_snake_case_name})
            # code when migration not finished
          end
          ```

          Since the check always returns `true`, the unless never executes. Remove the entire unless block.

          ### Pattern 5: Combined with feature flags - simplify to just feature flag

          When you see:
          ```ruby
          return if Feature.enabled?(:some_flag, group) &&
            ::Elastic::DataMigrationService.migration_has_finished?(:#{migration_snake_case_name})
          ```

          Since the migration check always returns `true`, simplify to:
          ```ruby
          return if Feature.enabled?(:some_flag, group)
          ```

          Similarly, for other boolean combinations:
          - `feature_flag && migration_has_finished?(:#{migration_snake_case_name})` → `feature_flag`
          - `migration_has_finished?(:#{migration_snake_case_name}) && feature_flag` → `feature_flag`
          - `!migration_has_finished?(:#{migration_snake_case_name}) || other_condition` → `other_condition`

          ### Pattern 6: Validation pattern - remove validation

          When you see:
          ```ruby
          raise Error unless ::Elastic::DataMigrationService.migration_has_finished?(:#{migration_snake_case_name})
          ```

          Since the check always returns `true`, this error is never raised. Remove the entire line.

          ### Pattern 7: Conditional rendering or query building

          When you see:
          ```ruby
          if ::Elastic::DataMigrationService.migration_has_finished?(:#{migration_snake_case_name})
            query_hash = add_new_field_to_query(query_hash)
          end
          ```

          Since the check always returns `true`, simplify to:
          ```ruby
          query_hash = add_new_field_to_query(query_hash)
          ```

          ### Pattern 8: Direct class name references

          If you see the class name `#{migration_class_name}` referenced directly (not through `migration_has_finished?`), handle it carefully:
          - If it's in a comment explaining historical context, consider removing or updating the comment
          - If it's importing or referencing the migration class for execution, this reference can likely be removed
          - If you're unsure, leave a comment: `# TODO: Review if #{migration_class_name} reference can be removed`

          ### Pattern 9: Version number references

          Migration version numbers may appear in comments or documentation. These can typically be removed if they're explaining why certain code exists. If in doubt, keep them.

          ### Important Guidelines

          1. **Be conservative**: If you're unsure whether code is dead, leave a TODO comment instead of removing it
          2. **Maintain functionality**: Only remove code that is provably unreachable
          3. **Consider context**: If the migration check is in a method that's only called for migration-related logic, the entire method might be removable
          4. **Look for patterns**: Often multiple conditionals for different migrations appear together; only simplify the one for `:#{migration_snake_case_name}`

          If there are no changes needed to the file, return it unchanged.
        MARKDOWN
      end

      def prompt_rspec(migration_class_name, migration_snake_case_name, file)
        <<~MARKDOWN
          #{prompt_ruby(migration_class_name, migration_snake_case_name, file)}

          ## Additional RSpec-Specific Instructions

          ### Test Stub Pattern 1: Stub returning true - remove stub

          When you see:
          ```ruby
          allow(::Elastic::DataMigrationService)
            .to receive(:migration_has_finished?)
            .with(:#{migration_snake_case_name})
            .and_return(true)
          ```

          Since `true` is now the actual behavior when the migration is obsolete, this stub is redundant. Remove it entirely.

          ### Test Stub Pattern 2: Stub returning false - remove test

          When you see:
          ```ruby
          allow(::Elastic::DataMigrationService)
            .to receive(:migration_has_finished?)
            .with(:#{migration_snake_case_name})
            .and_return(false)
          ```

          This stub is testing a scenario that can no longer occur (migration not finished). Remove the entire test example or context block that contains this stub.

          ### Test Stub Pattern 3: set_elasticsearch_migration_to helper - remove test

          When you see:
          ```ruby
          set_elasticsearch_migration_to(:#{migration_snake_case_name}, including: false)
          ```

          This helper sets the migration to an incomplete state, which can no longer occur when the migration is obsolete. Remove the entire test example or context block that contains this helper call.

          Similarly, if you see:
          ```ruby
          set_elasticsearch_migration_to(:#{migration_snake_case_name}, including: true)
          ```

          This is redundant since the migration is now always finished. Remove this helper call (but keep the rest of the test if it's testing other valid behavior).

          ### Test Context Pattern: Tests for both states - keep only the "finished" state

          When you see:
          ```ruby
          context 'when migration has finished' do
            # tests for finished state
          end

          context 'when migration has not finished' do
            # tests for not finished state
          end
          ```

          Remove the "when migration has not finished" context entirely, as this scenario is no longer possible.

          ### Shared Example Pattern

          If you see:
          ```ruby
          it_behaves_like 'a deprecated Advanced Search migration', <version>
          ```

          This is the correct pattern for obsolete migrations. Leave it unchanged.

          ### Factory/Fixture Pattern

          If you see factories or fixtures that create or reference the migration class, these may need to be removed if the tests no longer need them. Use your judgment based on whether the test is still testing valid behavior.

          ### Important Test Guidelines

          1. **Preserve meaningful coverage**: Don't remove tests that verify actual application behavior, only tests that specifically test migration-related conditional logic
          2. **Check for other stubs**: The same `allow` block might stub multiple migrations; only remove stubs for `:#{migration_snake_case_name}`
          3. **Cleanup empty contexts**: If removing tests leaves an empty context or describe block, remove the empty block as well
          4. **Update descriptions**: If a test description mentions "when migration has finished", consider simplifying the description since that's now the only state

          If there are no changes needed to the file, return it unchanged.
        MARKDOWN
      end

      def prompt_markdown(migration_class_name, migration_snake_case_name, file)
        <<~MARKDOWN
          Your job is to remove references to obsolete Advanced Search migrations from documentation. An obsolete migration is one that has been completed on all GitLab instances and is no longer needed.

          The migration class is called `#{migration_class_name}` and its snake_case name is `#{migration_snake_case_name}`.

          The code below is in a file named `#{file}` and may contain references to this obsolete migration.

          ## Markdown Documentation Migration Reference Removal Guidelines

          ### When to Remove References

          1. **Historical examples**: If the migration is used as an example of how migrations work, consider replacing it with a more recent migration or removing the example
          2. **Migration status checks**: If documentation shows how to check if `#{migration_snake_case_name}` has finished, this section can be removed
          3. **Troubleshooting guides**: If the migration is mentioned in troubleshooting steps, those steps may no longer be relevant

          ### When to Keep References

          1. **Changelog entries**: If this is a changelog file mentioning when the migration was added, keep the reference for historical record
          2. **General examples**: If the migration name is used as a generic example (like "migration_name" or as part of a template), keep it
          3. **Migration history**: If documenting the history of the Advanced Search migration system, keep historical references

          ### Guidelines

          - Be conservative with documentation changes
          - If in doubt, keep the reference
          - Focus on removing outdated information that might confuse users
          - Maintain the flow and readability of the documentation

          If there are no changes needed to the file, return it unchanged.
        MARKDOWN
      end
    end
  end
end
