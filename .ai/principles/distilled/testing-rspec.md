---
source_checksum: fab567b0daaf77a4
distilled_at_sha: 0bc240cb0e70d2bba500cca6317a5c7e9e06605e
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# RSpec (Backend Testing) Principles

## Checklist

### Test Levels and Placement

- Place unit tests in the corresponding `spec/` subdirectory matching the source path (for example, `app/models/` → `spec/models/`, `app/services/` → `spec/services/`, `lib/` → `spec/lib/`).
- Place feature (system) specs in `spec/features/`; name files `ROLE_ACTION_spec.rb` (for example, `user_changes_password_spec.rb`).
- Place EE-specific specs under `ee/spec/` following the same structure.
- Prefer request specs over controller specs; use request specs for API endpoints (GitLab is transitioning away from controller specs).
- DO NOT write a system/feature test when the behavior can be fully covered by unit or integration tests; use the lowest effective test level.
- Use system tests only when: the component is small, internal object/database state must be verified, and it cannot be tested at a lower level.
- DO NOT add `:js` to a feature spec unless the test genuinely requires JavaScript reactivity in the browser (headless browser is significantly slower).

### General RSpec Guidelines

- Use a single, top-level `RSpec.describe ClassName` block.
- Use `.method` to describe class methods and `#method` to describe instance methods.
- Use `context` to test branching logic (enforced by the `RSpec/AvoidConditionalStatements` RuboCop cop).
- Prefer table-based tests over multiple `context` blocks that differ only in their `let` values.
- Follow the Four-Phase Test pattern, using newlines to separate phases.
- Use `Gitlab.config.gitlab.host` rather than hard-coding `'localhost'`; use `example.com` / `gitlab.example.com` for literal URLs in tests.
- DO NOT assert against the absolute value of a sequence-generated attribute (IDs, IIDs, access levels); use `non_existing_record_id` / `non_existing_record_iid` / `non_existing_record_access_level` when you need a non-existent ID.
- DO NOT use `expect_any_instance_of` or `allow_any_instance_of` in RSpec.
- DO NOT supply the `:each` argument to hooks — it's the default.
- Prefer `before`/`after` hooks scoped to `:context` over `:all`.
- Use a Capybara matcher such as `find('.js-foo')` before calling `evaluate_script` or `execute_script` on an element, to ensure the element exists.
- Use `focus: true` to isolate parts of the specs you want to run.
- Use `:aggregate_failures` when there is more than one expectation in a test.
- Use `specify` rather than `it do` for empty test description blocks that are self-explanatory.
- Set feature category metadata on every RSpec example (see the feature categorization guide).
- Verify a new test fails in the expected way before asserting it passes — invert the condition or remove the behavior under test to confirm the failure message is meaningful.
- Add the `:eager_load` tag when a test depends on all application code being loaded.

### `subject` and `let` Variables

- Prefer `let_it_be` over `let` or `let!` for database-persisted objects that do not change between examples.
- Use `let_it_be_with_reload` when the test modifies the object and needs the database state rolled back between examples; use `let_it_be_with_refind` only when `reload` is insufficient.
- Use `let` to reduce duplication across an entire spec file; use local variables inside `it` blocks for variables used by only one test.
- DO NOT define a `let` variable inside the top-level `describe` block that is only used in a nested `context` — keep the definition as close as possible to where it is used.
- DO NOT define a `let` variable that's only used by the definition of another — use a helper method instead.
- Use `let!` only when strict evaluation with defined order is required.
- DO NOT reference `subject` directly in examples — use a named subject `subject(:name)` or a `let` variable instead.
- Treat objects inside `let_it_be` as immutable; use `freeze: true` to enforce immutability and detect state leakage.
- DO NOT use `let_it_be` when the factory uses stubs (`allow`); use `let` instead, or change the factory to avoid stubs.
- Ensure `let_it_be` blocks do not depend on a `before` block — `let_it_be` executes in `before(:all)` before per-example `before` hooks run.

### Common Test Setup

- Use `let_it_be` and `before_all` (from `test-prof`) instead of `before(:all)` / `before(:context)` to share objects across examples without manual cleanup.
- DO NOT use `let_it_be` or `before_all` in migration specs, Rake task specs, or specs tagged `:delete` — they do not work with DatabaseCleaner's deletion strategy; use `let` / `let!` and `before` instead.

### Table-Based / Parameterized Tests

- Include `using RSpec::Parameterized::TableSyntax` when using table syntax
- DO NOT use procs, stateful objects, or FactoryBot-created objects directly in `where` blocks — use `ref(:symbol)` instead

### Factories

- Place factory definitions in `spec/factories/`, named using the pluralization of their corresponding model
- Define only one top-level factory per file
- DO NOT define attributes in a factory that are not required for the record to pass validation
- Use traits to clean up factory definitions and usages
- Use implicit, explicit, or inline associations instead of `create`/`build` in callbacks for association setup
- When creating factories with `has_many` and `belongs_to` associations, use the `instance` method to refer to the object being built (prevents unnecessary record creation via interconnected associations).
- DO NOT use `skip_callback` in factories
- DO NOT use `allow(object).to receive(:method)` in factories (incompatible with `let_it_be`); use `stub_method` instead, and restore with `restore_original_method` / `restore_original_methods` in `after(:create)`.
- Use `stub_member_access_level` to stub member access levels for `build_stubbed` factory stubs; DO NOT use it when the test relies on persisted `project_authorizations` or `Member` records.
- Consider writing specs for factories that contain custom logic (for example, `after(:build)` hooks); place factory specs in `spec/factories_specs/`.

### Fixtures and Repositories

- Place all fixtures under `spec/fixtures/`.
- Use the `:repository` trait on project factories to get a copy of the `gitlab-test` repository; prefer `:custom_repo` when you need to specify exact file contents.

### Test Performance

- Prefer `build_stubbed` > `build` > `create`; DO NOT `create` an object when `build`, `build_stubbed`, `attributes_for`, `spy`, or `instance_double` suffices — database persistence is slow.
- Use `instance_double` and `spy` instead of `FactoryBot.build(...)` when no real object behavior is needed.
- Use `FactoryDefault` (`create_default`) with `factory_default: :keep` to reuse a single object for all calls to a named factory in implicit parent associations across a suite.
- Run `FDOC=1 bin/rspec` (Factory Doctor) to find unnecessary database persistence; run `FPROF=1 bin/rspec` (Factory Profiler) to identify repetitive factory creation and cascades.
- Use `bin/rspec-stackprof --speedscope=true <spec>` to generate a flamegraph and identify where a slow test spends its time.
- Combine multiple assertions on an expensive action into a single example rather than repeating the action; use `:aggregate_failures` when combining.
- Mock expensive external operations (shell-outs, Git commands, network calls, binary compilation) in feature and integration specs using `allow` / `expect(...).to receive(...)` stubs or RSpec doubles; if a unit test already verifies the output, stub it in higher-level specs.
- Profile slow specs with `bundle exec rspec --profile -- path/to/spec.rb` to identify the most expensive examples.
- DO NOT request capabilities you don't need (`:js`, `:clean_gitlab_redis_cache`, `:request_store`, etc.) — each adds setup overhead.
- Use `fast_spec_helper` instead of `spec_helper` for classes well-isolated from Rails (skips gem loading, Rails boot, Gitaly/Shell setup); use `rubocop_spec_helper` for RuboCop-related specs.
- Add `require_dependency '<gem>'` (preferably in the library file that needs it, otherwise in the spec) when a `fast_spec_helper` spec exercises code that depends on a gem not located in `lib/` (for example `re2` via `Gitlab::UntrustedRegexp`).
- Profile and optimize a slow shared example as a local spec before extracting it into a shared context; prefer `build_stubbed` or `build` over `create` in shared examples.

### System / Feature Tests

- Name feature spec files `ROLE_ACTION_spec.rb`; use scenario titles that describe success and failure paths.
- DO NOT use scenario titles that add no information (such as "successfully") or repeat the feature title.
- Test a happy path and one less-happy path — test all other paths with unit or integration tests.
- Test what is displayed on the page, not the internals of ActiveRecord models (for example, assert attributes appear on the page rather than checking `Model.count`).
- When a test must assert backend or model state after a UI action, first wait for a visible success indicator (`have_content`, `have_current_path`, `have_css`) and only then call `model.reload` — reading model state immediately after a Capybara action races the request.
- Confirm the page has reached the expected state with a positive matcher before the next interaction, assertion, database read, or navigation — DO NOT rely solely on `wait_for_requests` (it does not account for Vue re-render, redirect completion, async follow-up writes, or browser-initiated downloads).
- Use `have_no_link` / `have_no_*` (negative Capybara matchers) for absence checks — they return immediately when the element is absent; DO NOT use `expect(page.has_link?(...)).to be(false)` which waits the full timeout.
- Use `have_no_testid('<id>')` (not `not_to have_testid`) to assert a `data-testid` element is absent.
- Always confirm the page is loaded with a positive matcher before checking for absence.
- Use `wait: 0` only in conditional logic inside a region you have already confirmed is loaded; DO NOT use it for regular absence assertions.
- Query by element text label rather than by ID, class name, or `data-testid` where possible; use `within` with `data-testid` only for scoping to a container.
- Use specific Capybara actions (`click_button`, `click_link`, `fill_in`, `select`, `check`, `choose`, `attach_file`) rather than `find(...).click`.
- Use specific Capybara finders (`find_button`, `find_link`, `find_field`) rather than generic `find`; use `find_by_testid` only when no semantic finder applies.
- DO NOT use `all()` with `.first` or block iteration to filter elements — use `find()` or a CSS child selector with `.ancestor()` instead.
- Use specific Capybara matchers (`have_button`, `have_link`, `have_field`, `have_select`, `have_text`, `have_current_path`, `have_title`) rather than generic `have_css` where possible.
- Use `within_modal` helper to interact with GitLab UI modals; use `accept_gl_confirm` for confirmation modals that only need to be accepted.
- Use `be_axe_clean` matcher to run automated accessibility testing in feature tests.
- Call the same externalizing method (for example, `_('...')`) in RSpec expectations against externalized content
- Assert on a stable end-state (such as a status text or alert message) after an asynchronous mutation — DO NOT assert on a button's label or `disabled` state to synchronize, as controls pass through transient loading states before settling.
- Use the `wait_for` helper (from `spec/support/helpers/wait_helpers.rb`) only as a last resort when there is no visible UI outcome to assert on (for example, browser-initiated downloads or interactions that must be retried); DO NOT use the deprecated `wait_for_requests` in new specs.
- Assert with a waiting Capybara matcher (`have_field`, `have_selector`, `have_content`) rather than reading a value directly from an element (`find(...).value`, `find(...).text`, `all(...).count`) — direct reads capture state at that exact moment and race asynchronous updates.
- Use the `:enable_admin_mode` RSpec metadata tag to activate admin mode in specs; DO NOT use `enable_admin_mode!(admin, use_ui: true)` — it is slow and race-prone.
- Wrap both the triggering UI action and the assertion on its visible outcome inside `perform_enqueued_jobs` when testing delayed mail delivery — wrapping only the click can end the block before the AJAX request enqueues the job.

### View Specs

- Scope view specs to rendered HTML output using matchers such as `have_content`, `have_css`, `have_selector`, and `have_link`; DO NOT assert on internal Ruby state or return values of view helper methods.
- Use `build_stubbed` instead of `create` in view spec setup unless the spec genuinely requires persisted state; use `assign` for instance variables and `allow(view).to receive(...)` to stub helper methods.
- DO NOT include `ActiveRecord::QueryRecorder` or `exceed_query_limit` assertions in view specs — query performance belongs in request or controller specs.
- DO NOT use deep service-object mocking chains such as `receive_message_chain` in view specs.

### Rake Task Tests

- Use RSpec metadata tag `type: :task` or place specs in `spec/tasks/` to automatically include `RakeHelpers`.
- Use the `run_rake_task('<namespace>:<task>')` helper (from `RakeHelpers`) to execute the task under test.
- Use `:silence_stdout` to redirect `$stdout`; use `:silence_output` to silence both `$stdout` and `$stderr`.

### Time-Sensitive Tests

- Use `ActiveSupport::Testing::TimeHelpers` (`travel_to`, `freeze_time`) for any test that exercises time-sensitive behavior
- Give records distinct timestamps when a test orders by a timestamp column (use `travel_to` with explicit offsets) — equal timestamps produce non-deterministic ordering.
- DO NOT hardcode future-date constants in specs that gate behavior on "today" — use `travel_to` or compute the date relative to `Time.current`.
- Use `:freeze_time` or `time_travel_to:` RSpec metadata tags to reduce boilerplate for time-frozen specs
- Call `.reload` on objects after database writes when comparing timestamps — Active Record timestamps may have higher precision than PostgreSQL's microsecond resolution, causing equality checks to fail.

### Pristine Test Environments

- DO NOT rely on the value of an ID or any other sequence-generated column across specs
- Mark specs that make direct Redis calls with `:clean_gitlab_redis_cache`, `:clean_gitlab_redis_shared_state`, or `:clean_gitlab_redis_queues` as appropriate.
- Use the `:sidekiq_inline` trait when a test requires Sidekiq to actually process jobs.
- Use `stub_const` to modify constants in specs (ensures the change is rolled back); use `stub_env` to modify `ENV`.
- Use `:permit_dns` to bypass universal DNS stubbing when a test genuinely requires DNS resolution.
- Mark Elasticsearch specs with `:elastic` or `:elastic_delete_by_query` metadata; use `:elastic_clean` only when the other traits cause issues (it is significantly slower)
- Use `stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)` to enable Elasticsearch in specs; call `ensure_elasticsearch_index!` after loading data to make it searchable.
- Add the `:prometheus` tag to RSpec tests that exercise Prometheus metrics to ensure metrics are reset before each example.
- Use `stub_file_read` / `expect_file_read` helpers to stub `File.read`; DO NOT stub `File.read` globally without also calling the original for other paths.
- DO NOT specify a `path` override on `:legacy_storage` projects — the default path includes the project ID and avoids repository conflicts between specs.
- Use `:disable_rate_limit` when a single test triggers rate limiting; use `:clean_gitlab_redis_rate_limiting` when rate limiting is triggered across multiple examples in a feature spec using `:js`.

### Matchers and Assertions

- Use `have_gitlab_http_status` (with named status symbols like `:ok`, `:no_content`) instead of `have_http_status` or `expect(response.status).to` — it shows the response body on mismatch.
- Use `be_like_time` or `be_within` when comparing timestamps from the database to Ruby `Time` objects (precision differs between OS and PostgreSQL).
- Use `match_schema` / `match_response_schema` to validate JSON responses against a JSON schema.
- Use `be_valid_json` to validate that a string parses as JSON; combine with `match_schema` using `.and`.
- Use `expect_snowplow_event` to assert legacy Snowplow tracking calls (catches runtime type-check errors); use `expect_no_snowplow_event` with at least a `category` argument to avoid flakiness.
- Use `match_snowplow_context_schema` to validate Snowplow context against a JSON schema in `spec/fixtures/product_intelligence/`.
- DO NOT assert N+1 or query counts in feature (`:js`) specs — put `QueryRecorder` and `exceed_query_limit` assertions in request or controller specs; prime the baseline with a warmup request when the first call lazily loads caches.
- Use `Gitlab::GitalyClient.get_request_count` to assert the number of Gitaly requests made by a block of code.

### Shared Examples and Helpers

- Declare shared contexts or shared examples used by only one spec file inline in that file.
- Place shared examples used within a single bounded context in that context's directory structure; place shared examples used across multiple bounded contexts under `spec/support/shared_*`.
- DO NOT change RSpec configuration inside helpers modules — add `config.include` calls in `spec/spec_helper.rb` or scope them with type modifiers.
- Place helper modules under `spec/support/helpers/`, following Rails naming conventions (`spec/support/helpers/` is the root).
- Place RSpec configuration files under `spec/support/`, one file per domain.

### Test Order and Flakiness

- Ensure new spec files can run in random order; check order dependency with `scripts/rspec_check_order_dependence spec/path/to/spec.rb` and remove the file from `rspec_order_todo.yml` once it passes.
- DO NOT make specs depend on test execution order — use `rspec --bisect` to identify order-dependent failures.

### Ruby Constants in Tests

- Test the behavior that depends on a constant rather than the value of the constant itself; DO NOT write tests that merely repeat the constant's values.

### Branch Coverage

- For conditional logic (`||`, `&&`, `if/else`, `case`), verify each branch has test coverage
- For helper methods, ensure unit specs exist (not just integration coverage)
- For ActiveRecord callbacks (`before_validation`, `before_save`), ensure unit specs test the callback behavior specifically

### Edge Case Coverage

- Flag missing edge case coverage for:
  - Nil/empty values
  - Boundary conditions
  - Fallback logic (`||` operators)
  - Error states

### Feature Flags in Tests

- All feature flags are enabled by default in the test environment (regardless of the `default_enabled:` value in the YAML definition), so DO NOT stub a flag to `true` to reach its enabled path — the only exception is a flag explicitly disabled in `spec/spec_helper.rb`, where stubbing to `true` is warranted
- Only use `stub_feature_flags(flag: false)` to test the disabled code path.

### Spec File Paths

- DO NOT create a new spec file in a subdirectory when a spec already exists at the canonical path (e.g., modify `spec/requests/api/pages_spec.rb`, DO NOT create `spec/requests/api/pages/pages_spec.rb`)
- DO NOT remove existing shared examples when adding or fixing coverage; extend them or add new examples alongside

### Test Design

- Use shared examples to reduce duplication across specs
- Write error-handling tests for security-sensitive operations
- Write input-validation tests for user-facing endpoints
- Follow the testing pyramid: most tests at the unit level, fewer at the integration/system level

### Deterministic Assertions

- When asserting on a collection where order does not matter, use `match_array` instead of `eq` or `match` to avoid dataset-specific flakiness
- DO NOT call `.first`, `.last`, or `.take` on an ActiveRecord relation without an explicit `.order(...)` — PostgreSQL does not guarantee row order without ORDER BY, which causes dataset-specific flaky tests
- When using `Faker` or random values, ensure the test handles any value the generator can produce; if the test depends on a specific format, use a hardcoded value instead

## Authoritative sources

For the full picture, see:

- doc/development/testing_guide/_index.md
- doc/development/testing_guide/best_practices.md
- doc/development/testing_guide/testing_levels.md
- doc/development/testing_guide/testing_rake_tasks.md

