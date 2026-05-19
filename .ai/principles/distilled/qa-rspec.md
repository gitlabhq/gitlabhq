---
source_checksum: 1cb9cedfca568de2
distilled_at_sha: 52964caf288c3d9936b8ce4a3d2242c1f92567fa
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# RSpec (Backend Testing) Principles

## Checklist

### General RSpec Guidelines

- Use a single, top-level `RSpec.describe ClassName` block.
- Use `.method` to describe class methods and `#method` to describe instance methods.
- Use `context` to test branching logic.
- Prefer table-based tests over multiple `context` blocks that differ only in their `let` values.
- Follow the Four-Phase Test pattern, using newlines to separate phases.
- Use `Gitlab.config.gitlab.host` rather than hard-coding `'localhost'`.
- Use `example.com` or `gitlab.example.com` for literal URLs in tests.
- DO NOT assert against the absolute value of a sequence-generated attribute.
- DO NOT use `expect_any_instance_of` or `allow_any_instance_of` in RSpec.
- DO NOT supply the `:each` argument to hooks — it's the default.
- Prefer `before`/`after` hooks scoped to `:context` over `:all`.
- Use `find('.js-foo')` (or equivalent Capybara matcher) before calling `evaluate_script` or `execute_script` on an element to ensure it exists
- Use `:aggregate_failures` when there is more than one expectation in a test.
- Use `specify` rather than `it do` for empty test description blocks that are self-explanatory.
- Use `non_existing_record_id`/`non_existing_record_iid`/`non_existing_record_access_level` when you need an ID/IID/access level that doesn't actually exist — DO NOT use hardcoded values like 123 or 999.
- Verify a new test fails in the expected way before asserting it passes — invert the condition or remove the behavior under test to confirm the failure message is meaningful.
- Set feature category metadata for each RSpec example.

### Branch Coverage

- For conditional logic (`||`, `&&`, `if/else`, `case`), verify each branch has test coverage.
- For helper methods, ensure unit specs exist (not just integration coverage).
- For ActiveRecord callbacks (`before_validation`, `before_save`), ensure unit specs test the callback behavior specifically.

### Edge Case Coverage

- Flag missing edge case coverage for:
  - Nil/empty values
  - Boundary conditions
  - Fallback logic (`||` operators)
  - Error states

### Feature Flags in Tests

- DO NOT use `stub_feature_flags(flag: true)` — feature flags are enabled by default in the test environment, so stubbing to `true` is redundant and misleading.
- Only use `stub_feature_flags(flag: false)` to test the disabled code path.
- For the enabled case, write tests without any feature flag stub — the default state is already enabled.

### Spec File Paths

- DO NOT create a new spec file in a subdirectory when a spec already exists at the canonical path (e.g., modify `spec/requests/api/pages_spec.rb`, DO NOT create `spec/requests/api/pages/pages_spec.rb`)
- DO NOT remove existing shared examples when adding or fixing coverage; extend them or add new examples alongside

### `subject` and `let` Variables

- Prefer table-based/parameterized tests instead of repeating `let` definitions across contexts.
- Prefer `let!` over instance variables, `let` over `let!`, and local variables over `let`.
- Use `let` to reduce duplication throughout an entire spec file.
- DO NOT use `let` to define variables used by a single test — define them as local variables inside the `it` block.
- DO NOT define a `let` variable inside the top-level `describe` block that's only used in a more deeply-nested `context` or `describe` block.
- DO NOT override the definition of one `let` variable with another.
- DO NOT define a `let` variable that's only used by the definition of another — use a helper method instead.
- Use `let!` only when strict evaluation with defined order is required.
- DO NOT reference `subject` directly in examples — use a named subject `subject(:name)` or a `let` variable instead.

### Table-Based / Parameterized Tests

- Include `using RSpec::Parameterized::TableSyntax` when using table syntax
- DO NOT use procs, stateful objects, or FactoryBot-created objects directly in `where` blocks — use `ref(:symbol)` instead

### Factory Usage and Test Performance

- Prefer `build_stubbed` or `build` over `create` when database persistence is not required
- Prefer `instance_double` and `spy` over `FactoryBot.build(...)` for pure isolation
- Use `let_it_be` instead of `let` for database-backed objects that do not change between examples
- Use `let_it_be_with_reload` when the object must be modified in a `before` block across examples
- Use `let_it_be_with_refind` only when a completely fresh object instance is required per example (note: incompatible with `stub_method`)
- Treat objects inside `let_it_be` as immutable; use `freeze: true` to enforce this
- DO NOT use `allow(object).to receive(:method)` stubs inside factories — use `stub_method` instead (factories only)
- DO NOT use `stub_method` outside of factories — use RSpec mocks instead
- Use `create_default` with `factory_default: :keep` to share a single default object across all examples in a suite and avoid factory cascades
- DO NOT use `let_it_be` or `before_all` in migration specs, Rake task specs, or specs tagged `:delete` — use `let`/`let!` and `before` instead
- DO NOT use `before(:all)` or `before(:context)` for common test setup — use `let_it_be` and `before_all` instead
- Ensure `let_it_be` blocks do not depend on a `before` block — `let_it_be` executes in `before(:all)` before per-example `before` hooks run
- Use `stub_member_access_level` to stub member access levels for `build_stubbed` objects; DO NOT use this helper when the test relies on persisted `project_authorizations` or `Member` records

### Test Slowness

- DO NOT add the `:js` metadata to a feature spec unless the test requires JavaScript reactivity in the browser
- Use `have_no_testid` instead of `not_to have_testid` — the latter waits the full Capybara timeout before concluding the element is absent
- Pass `wait: 0` to Capybara matchers inside a container already confirmed as loaded when asserting element absence; DO NOT use `wait: 0` on the container itself
- Mock external processes (shell-outs, Git commands, network calls, binary compilation) in feature and integration specs — DO NOT trigger real external operations when the logic under test is already covered by unit tests
- Profile and optimize a slow shared example as a local spec before extracting it into a shared context
- Prefer `build_stubbed` or `build` in shared examples — DO NOT use `create` unless the contract explicitly requires database state

### View Specs

- DO NOT re-test backend logic or database behavior in view specs — assertions must target rendered output using matchers such as `have_content`, `have_css`, `have_selector`, and `have_link`.
- Use `build_stubbed` instead of `create` in view spec setup unless the spec genuinely requires persisted state.
- Use `assign` to pass instance variables and `allow(view).to receive(...)` to stub helper methods in view specs.
- DO NOT include `ActiveRecord::QueryRecorder` or `exceed_query_limit` assertions in view specs — query performance belongs in request or controller specs.
- DO NOT use deep service-object mocking chains such as `receive_message_chain` in view specs.

### System / Feature Tests

- Name feature specs `ROLE_ACTION_spec.rb` (for example, `user_changes_password_spec.rb`).
- DO NOT use scenario titles that add no information (such as "successfully") or repeat the feature title.
- Create only the necessary records in the database.
- Test a happy path and one less-happy path — test all other paths with unit or integration tests.
- Test what's displayed on the page, not the internals of ActiveRecord models.
- Query by element text label rather than by ID, class name, or `data-testid` in UI tests.
- Use `within` with a `data-testid` selector only to scope interactions to a specific page area
- Use semantic Capybara actions (`click_button`, `click_link`, `fill_in`, `select`, `check`, `choose`, `attach_file`) — DO NOT use `find(...).click` or `send_keys` when a semantic action is available
- Use semantic Capybara finders (`find_button`, `find_link`, `find_field`) — use `find_by_testid` only when the element is not a button, link, or field
- DO NOT use `all()` with `.first` or block iteration to filter elements — use `find()` or a CSS child selector with `.ancestor()` instead.
- Use semantic Capybara matchers (`have_button`, `have_link`, `have_field`, `have_select`, `have_checked_field`) — use `have_css` only when no specific matcher applies
- Use `within_modal` helper to interact with GitLab UI modals.
- Call the same externalizing method (for example, `_('...')`) in RSpec expectations against externalized content
- Use `be_axe_clean` matcher to run automated accessibility testing in feature tests.

### Time-Sensitive Tests

- Use `ActiveSupport::Testing::TimeHelpers` (`travel_to`, `freeze_time`) for any test that exercises time-sensitive behavior
- Use `:freeze_time` or `time_travel_to:` RSpec metadata tags to reduce boilerplate for time-frozen specs
- Reload objects created before time-frozen examples to get timestamps with correct database precision (avoid timestamp truncation mismatches)

### Query Performance Tests

- Use `QueryRecorder` to assert that N+1 problems do not exist and that query counts do not increase unnoticed
- Use `Gitlab::GitalyClient.get_request_count` to assert Gitaly request counts in a given block

### Shared Contexts and Shared Examples

- Place shared examples used only within one bounded context in that context's directory structure
- Place shared examples used across multiple bounded contexts under `spec/support/shared_*`
- DO NOT move shared examples to `spec/support/shared_*` unless they are actually shared across different bounded contexts

### Helpers

- Place helpers shared across spec files under `spec/support/helpers/`
- Follow Rails naming/namespacing convention where `spec/support/helpers/` is the root
- DO NOT modify RSpec configuration inside helper modules — include helpers explicitly in specific specs or via `RSpec.configure` in support files

### Fast Unit Tests

- Use `require 'fast_spec_helper'` instead of `require 'spec_helper'` for classes well-isolated from Rails
- Add `require_dependency` for gems not in `lib/` that are needed by `fast_spec_helper` specs
- Use `rubocop_spec_helper` for RuboCop-related specs

### Factories

- Place factory definitions in `spec/factories/`, named using the pluralization of their corresponding model
- Define only one top-level factory per file
- Use traits to clean up factory definitions and usages
- DO NOT define attributes in a factory that are not required for the record to pass validation
- DO NOT supply attributes when instantiating from a factory that are not required by the test
- Use implicit, explicit, or inline associations instead of `create`/`build` in callbacks for association setup
- Use the `instance` method when creating factories with `has_many`/`belongs_to` associations to prevent creation of unnecessary records
- DO NOT use `skip_callback` in factories

### Migration Tests

- Write migration tests for all post-migrations (`/db/post_migrate`) and background migrations.
- Write migration tests for all data migrations.
- Use `require_migration!` to load migration files in specs — DO NOT rely on Rails autoloading
- Use the `table` helper to create temporary `ActiveRecord::Base`-derived models — DO NOT use FactoryBot in migration specs.
- Use `migrate!` helper to run the migration under test.
- Use `reversible_migration` helper to test migrations with `change` or both `up` and `down` hooks.
- DO NOT use `let_it_be`, `let_it_be_with_reload`, `let_it_be_with_refind`, or `before_all` in migration specs — use `let`, `let!`, `before`, or `before(:all)` instead.
- Tag specs against a non-default database schema (for example, `:gitlab_ci`) with the appropriate `migration:` RSpec tag.

### Rake Task Tests

- Use RSpec metadata tag `type: :task` or place specs in `spec/tasks/` to automatically include `RakeHelpers`.
- Use `run_rake_task(<task>)` to execute Rake tasks in specs.
- Add `:silence_stdout` metadata to redirect `$stdout` in Rake task specs.

### Matchers

- Use `have_gitlab_http_status` over `have_http_status` or `expect(response.status).to` — it displays the response body on mismatch
- Use named HTTP status symbols (`:ok`, `:no_content`) over numeric codes
- Use `be_like_time` or `be_within` when comparing timestamps from the database to Ruby `Time` objects
- Use `match_schema` / `match_response_schema` to validate JSON responses against a schema
- Use `expect_snowplow_event` to test Snowplow tracking calls — DO NOT mock `Gitlab::Tracking` directly
- Specify at least a `category` argument when using `expect_no_snowplow_event` to avoid flaky failures from unrelated tracking calls
- Use `have_no_testid` instead of `not_to have_testid`

### EE-Specific and SaaS Tests

- Use `if: Gitlab.ee?` or `unless: Gitlab.ee?` on context/spec blocks for tests that depend on EE license
- Follow the SaaS-only features testing guide for tests that depend on SaaS behavior

### Pristine Test Environments

- DO NOT rely on the value of an ID or any other sequence-generated column across specs
- DO NOT manually specify values for sequence-generated columns — look up the value after the row is created
- Mark specs that make direct Redis calls with `:clean_gitlab_redis_cache`, `:clean_gitlab_redis_shared_state`, or `:clean_gitlab_redis_queues` as appropriate.
- Use the `:sidekiq_inline` trait when a test requires Sidekiq to actually process jobs.
- Use `stub_file_read` and `expect_file_read` helpers to stub file contents — DO NOT stub `File.read` globally
- Use `stub_const` to modify constants in specs — DO NOT modify constants directly
- Use `stub_env` to modify `ENV` in specs.
- Mark Elasticsearch specs with `:elastic` or `:elastic_delete_by_query` metadata; use `:elastic_clean` only when the other traits cause issues (it is significantly slower)
- Add the `:prometheus` tag to RSpec tests that exercise Prometheus metrics to ensure metrics are reset before each example.

## Authoritative sources

For the full picture, see:

- doc/development/testing_guide/_index.md
- doc/development/testing_guide/best_practices.md
- doc/development/testing_guide/testing_levels.md
- doc/development/testing_guide/testing_migrations_guide.md
- doc/development/testing_guide/testing_rake_tasks.md

