---
source_checksum: a1b021dbce0f673e
distilled_at_sha: 0bc240cb0e70d2bba500cca6317a5c7e9e06605e
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# End-to-End Testing Principles

## Checklist

### Test Structure and Naming

- Use `RSpec.describe` for the DevOps stage name, `describe` for the feature under test, `context` for conditions, and `it` for the expected result, so that the full test name reads as a sentence.
- Begin `context` block descriptions with `when`, `with`, `without`, `for`, `and`, `on`, `in`, `as`, or `if` (enforced by the `RuboCop/RSpec/ContextWording` cop).
- Add a `testcase:` RSpec metadata tag linking every test to its corresponding test case URL in the GitLab project test cases (`https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/:id`).
- For parallelized, templated, or shared-example tests that have a one-to-many relationship between a spec line and test cases, pass the `testcase` URL as an argument to `it_behaves_like` rather than using the `testcase:` tag directly.
- Split tests across separate files to maximize parallelization; Exception: when tests share expensive setup that would be wasteful to repeat per file.

### Page Objects

- Implement all page interactions through page objects — DO NOT invoke Capybara methods directly in spec files.
- Define every element used by a page object with the `element` DSL method and a corresponding `data-testid` attribute in the view; DO NOT use string/regexp pattern matching in `element` declarations (forbidden by the `QA/ElementWithPattern` RuboCop cop).
- Name elements using the `<descriptor>-<type>` kebab-case formula (e.g., `username-field`, `edit-button`, `clone-dropdown`); use only the approved type suffixes (`-button`, `-checkbox`, `-container`, `-content`, `-dropdown`, `-field`, `-link`, `-modal`, `-placeholder`, `-radio`, `-tab`, `-menu_item`).
- Mark elements that always appear on a page unconditionally with `required: true` to enable dynamic element validation on navigation and click.
- DO NOT use `data-qa-selector` attributes in new page objects; use `data-testid` exclusively (`data-qa-selector` is deprecated).
- Use `data-qa-*` extensible attributes (e.g., `qa_issue_title: issue.title`) to select a specific item from a list rather than relying on text matching.
- Run `bin/qa Test::Sanity::Selectors` locally to validate page object selectors; the `qa:selectors` CI job enforces this on every push.
- Define EE-specific page concerns by extending `QA::Page::PageConcern`, overriding `self.prepended`, calling `super` first, and wrapping `include`/`prepend` and `view`/`element` definitions inside `base.class_eval`.
- Use `click_` prefix for page object methods that select a single link or button; use `go_to_` prefix for methods that interact with multiple elements to navigate to a page.
- Name `.perform` block arguments using the snake_case page object name (e.g., `members`, `merge_request`); DO NOT use `page` (shadows Capybara DSL) or overly long names; use `new_page` when `new` would be ambiguous.

### Resources

- Inherit all resource classes from `Resource::Base` and implement `#fabricate!` using only page objects for browser UI interactions.
- Implement `#api_get_path`, `#api_post_path`, and `#api_post_body` to enable API fabrication.
- Prefer `fabricate_via_api!` (or the FactoryBot `create` helper) over `fabricate_via_browser_ui!` to save time and cost.
- Use the `attribute` method with a block to declare resource attributes that depend on other resources or must be populated from the page; remember that all attributes are lazily constructed — call an attribute method before navigating away from the page where it is populated.
- Use `populate(:attr)` inside `#fabricate!` to eagerly construct attributes that must be captured immediately after creation.
- Add any resource that cannot be deleted to the `IGNORED_RESOURCES` list in `qa/qa/tools/test_resources_handler.rb`.
- Use a `Commit` resource (HTTP API) instead of `ProjectPush` (Git CLI) for creating repository commits; Exception: when the test specifically covers SSH integration or Git CLI behavior.

### Flows

- Use `Flow::Login.sign_in` (and `Flow::Login.while_signed_in`) for authentication steps rather than duplicating login page interactions across tests.
- Encapsulate frequently repeated multi-page sequences into flow classes under `QA::Flow` rather than repeating them inline.

### Fabrication and Setup

- Fabricate resources via the API wherever possible; reserve browser UI fabrication for cases where no API exists.
- Use instance variables in `before(:all)` / `before(:context)` blocks (not `let`) for resources that can be shared across multiple examples, to avoid redundant creation; use `let` when the resource cannot be shared.
- Limit `before(:context)` hooks to API calls, non-UI operations, or basic UI operations such as login — complex UI setup in `before(:context)` prevents screenshot capture on failure.
- Use only non-UI operations in `after` hooks; UI operations in `after` move the browser state away from the failure point and prevent accurate screenshots.
- Ensure every test signs out (or does not leave the browser logged in) at the end of `after(:context)` / `before(:context)` blocks that perform UI actions, so subsequent tests can sign in cleanly.

### Expectations and Assertions

- DO NOT add `expect()` statements unrelated to what the test is verifying — keep tests lean.
- Use `aggregate_failures` (inline block or `:aggregate_failures` metadata) when a test must contain multiple expectations, so all failures are reported together.
- DO NOT wrap multiple actions and assertions in a single `expect { ... }.not_to raise_error` block; keep actions and assertions separate for clearer failure logs.
- Create custom negatable matchers (using `match_when_negated` with `has_no_*` predicate methods) for page object predicates used with `not_to`; DO NOT rely on `not_to have_*` without a negatable matcher, as it waits the full timeout before failing.
- Use `eventually_` matchers (e.g., `expect { value }.to eventually_eq(x).within(max_duration: 120)`) for expectations that require waiting on asynchronous state.

### Waits and Timing

- DO NOT use hard-coded `sleep` calls to wait for readiness; use framework helpers (`Support::Retrier`, `Support::Waiter`) or resource readiness checks (e.g., `runner.wait_until_online`) that poll for the correct signal.
- Wait for a signal that confirms backend work is complete (a visible element, a resource state, or an API response) before asserting or acting on a resource.
- When a wait times out, fix the signal being waited on rather than simply increasing the timeout.

### Navigation

- Navigate to pages directly (e.g., `issue.visit!`) rather than using `page.go_back` or browser history, which can land on unexpected pages.
- Scroll elements into view with `scroll_to_element` before interacting with controls that may be below the fold, to avoid `element click intercepted` or stale element failures.
- Blur elements by clicking another element that does not alter test state; use `click_element_coordinates` when a mask or overlay blocks the page; DO NOT click `body` to blur, as it can unintentionally trigger other elements.

### Execution Context Selection

- Use `only:` metadata to restrict a test to specific environments, pipelines, or jobs (e.g., `only: :production`, `only: { pipeline: :nightly }`, `only: { job: 'ee:instance' }`).
- Use `except:` metadata to exclude a test from specific environments, pipelines, or jobs.
- DO NOT combine `:production` and a `{ <switch>: 'value' }` hash in the same `only:`/`except:` — they are mutually exclusive; control production matching via `tld` and `domain` independently.
- When a test has `before` or `after` blocks, apply `only:`/`except:` metadata to the outer `RSpec.describe` block, not the `it` block.
- Use `quarantine: { only: { subdomain: :staging } }` syntax to quarantine a test only for a specific environment.

### Feature Flags

- Apply the `feature_flag: { name: 'flag_name' }` RSpec tag to every test that enables a feature flag, so it is skipped on environments where it should not run.
- Set `scope: :global` in the `feature_flag` metadata when the flag is enabled instance-wide, to skip the test on all live `.com` environments; omit `scope` or use a scoped value (`:project`, `:group`, `:user`) to skip only on canary, production, and pre-production.
- Prefer enabling feature flags for a specific project, group, user, or feature group rather than globally (`Runtime::Feature.enable(:flag, project: project)`); DO NOT enable flags globally unless necessary.
- Still apply `:requires_admin` when the test performs other admin actions unrelated to the feature flag toggle.
- When a new feature replaces a component behind a feature flag, add the new selector to the page object with the same name as the old one and keep the old selector in place; add a comment to delete the old selector when the flag is removed.
- When a resource class must behave differently based on a feature flag, use an `activated` boolean variable (defaulting to `false` in `initialize`) toggled at fabrication time; clean up the variable and conditions after the flag is removed.
- Add a wait for elements that are only visible with an active feature flag on static environments, where caching is not disabled, to avoid flakiness.
- Confirm that E2E tests pass with a feature flag enabled before enabling it on staging or GitLab.com; when a feature flag definition file is added or edited in an MR, the `cng-instance` and `cng-instance-ff-inverse` `e2e:test-on-cng` jobs run automatically to verify both states.

### Administrator Access

- Apply the `:requires_admin` RSpec metadata tag to every test that requires administrator access, to prevent it from running against production and other restricted environments.

### Class and Module Naming

- Follow the default Zeitwerk snake_case-to-PascalCase inflection for QA class and module filenames; add custom inflections only in the `loader.inflector.inflect` block in `qa/qa.rb`.

### Logging

- Use Rails `logger` instead of `puts` for all log output in QA code, to enable log-level control, tagging, and auto-formatting.

## Authoritative sources

For the full picture, see:

- doc/development/testing_guide/end_to_end/style_guide.md
- doc/development/testing_guide/end_to_end/beginners_guide/flows.md
- doc/development/testing_guide/end_to_end/beginners_guide/page_objects.md
- doc/development/testing_guide/end_to_end/beginners_guide/resources.md
- doc/development/testing_guide/end_to_end/best_practices/_index.md
- doc/development/testing_guide/end_to_end/best_practices/dynamic_element_validation.md
- doc/development/testing_guide/end_to_end/best_practices/execution_context_selection.md
- doc/development/testing_guide/end_to_end/best_practices/feature_flags.md
- doc/development/testing_guide/end_to_end/best_practices/waits.md

