---
source_checksum: c7e9410a688b66d0
distilled_at_sha: f22602e37afb92eb7028b601a922ebde417df6e4
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Frontend Testing Principles

## Checklist

### Test Coverage

- Write unit and feature tests for all new features.
- Write regression tests for bug fixes to prevent recurrence.

### What to Test

- DO NOT test Vue library internals (computed props, reactivity); test rendered template output instead.
- DO NOT test that mocks work; use mocks to support tests, not as the target of assertions.
- DO NOT use imported constants in assertions; use explicit literal values instead.
- Prefer testing components as close to the user's flow as possible (trigger DOM events, validate markup changes).
- DO NOT assert against `wrapper.vm` properties; assert against component behaviour through side effects: rendered HTML/components, API calls, etc.

### DOM Querying

- Use `findByRole` (DOM Testing Library) as the primary query method to enforce accessibility.
- Use `findComponent(FooComponent)` or `find('input[name=foo]')` or `find('[data-testid="..."]')` for unit tests.
- DO NOT use template refs (`wrapper.find({ ref: 'foo' })`) or any CSS classes (including `.js-*`) for test queries.
- Use `kebab-case` for `data-testid` attribute values.
- DO NOT add `.js-*` classes solely for testing purposes.

### Naming Conventions

- Name unit/component test files `${componentName}_spec.js`.
- Use the method name directly (without `#` or `.` prefix) as the `describe` block name when testing specific methods.

### Promises and Async

- Make all Promise-based tests asynchronous using `async/await` or by returning the Promise.
- DO NOT use `done` or `done.fail` callbacks when working with Promises.
- DO NOT leave Promise rejections unhandled in tests.
- Use `await nextTick()` to wait for Vue re-renders.
- Use `await waitForPromises()` when Promises are triggered in synchronous lifecycle hooks.
- DO NOT use `setTimeout` or `setImmediate` for waiting in tests; use `jest.runAllTimers`, `jest.runOnlyPendingTimers`, or Promise-based helpers instead.

### Time Manipulation

- Use `jest.runAllTimers` or `jest.runOnlyPendingTimers` instead of real timers; Jest uses fake timers by default.
- Use `useFakeDate` helper (not inline `Date` manipulation) to change the fake date within a `describe` block.
- DO NOT call `useFakeDate` or `useRealDate` inside `it`, `beforeEach`, or `beforeAll` blocks.
- Use `useRealDate` helper when real `Date` behavior is required.
- Use `setWindowLocation` helper to set `window.location.href` in tests.
- Use `useMockLocationHelper` when asserting that `window.location` methods were called.

### Test Isolation

- Set up component in `beforeEach`; use `afterEach` to null out Apollo/store references.
- Test that event listeners and timeouts are cleared when a component is destroyed (`beforeDestroy`/`beforeUnmount`).
- Modify `gon`/`window.gon` directly in `beforeEach` for tests that depend on it; it resets automatically between tests.

### Jest Matchers

- Use `toBe` (not `toEqual`) when comparing primitive values.
- Use specific matchers (`toHaveLength`, `toBeUndefined`, etc.) over generic ones for clearer error messages.
- DO NOT use `toBeTruthy` or `toBeFalsy`; use exact matchers instead.
- DO NOT use `toBeDefined` to assert element existence; use `.exists()).toBe(true)` instead.

### Mocking

- DO NOT use manual mocks (`__mocks__/` next to source) for non-`node_modules` modules; place them in `spec/frontend/__helpers__/mocks` instead.
- DO NOT use manual mocks when a mock is only needed by a few specs; use `jest.mock(..)` in the relevant spec file instead.
- Keep mocks short and focused; add a top-level comment explaining why the mock is necessary.
- Place manual mocks for `node_modules` packages in `spec/frontend/__mocks__`.

### Apollo / Local-only Queries

- Map resolvers to queries/mutations when creating the wrapper for `@client` directive tests.
- Pass four arguments to resolver assertions: `{}`, input variables object, `expect.anything()`, `expect.anything()`.

### Data-driven Tests

- Use `it.each` / `describe.each` for parameterized tests to reduce repetition.
- Use array block syntax (not template literal block) when pretty-printed output is needed (for example, empty strings, nested objects).

### Non-determinism

- Ensure test collaborators (Axios, Apollo, Date) behave consistently; use fakes/mocks for non-deterministic globals.
- DO NOT create the test subject more than once within a single test.
- Use `jest.spyOn(Math, 'random').mockReturnValue(...)` when the subject depends on `Math.random`.

### Console Warnings and Errors

- Ensure tests fail on unexpected `console.error` or `console.warn` calls.
- Use `ignoreConsoleMessages` helper sparingly and only when absolutely necessary for test maintainability.

### Snapshots

- Use snapshot tests only when other methods (VTU element assertions) do not cover the use case.
- DO NOT use snapshots to assert component logic, predict data structures, or test UI elements from external libraries (for example, GitLab UI).
- Treat snapshot files as code; review and understand their content.
- Prefer explicit VTU assertions (`.exists()`, `.text()`, element counts) over snapshots for element visibility, text presence, and complex HTML.

### MSW Integration Tests

- Default to MSW integration tests (`spec/frontend/msw_integration/`) over Capybara feature tests; use Capybara only when real backend state, navigation across server-rendered pages, server-side validations, or multi-Vue-app behavior on the same page is required.
- Use `fullMount` from `test_helpers.js` (wraps `mount` and attaches to `document.body`) to mount the root component with the real `apolloProvider`.
- Use native DOM APIs for all interactions and assertions in MSW integration tests; DO NOT use VTU wrapper methods (`wrapper.find()`, `wrapper.trigger()`, `wrapper.text()`, etc.).
- DO NOT mock child components in MSW integration tests.
- Reset the Apollo cache in `beforeEach` and stop the client in `afterEach` to prevent state leakage.
- DO NOT add `afterEach` cleanup for wrapper destruction or Apollo client teardown in MSW test files; `test_setup.js` handles this globally.
- DO NOT add `server.listen`, `server.resetHandlers`, or `server.close` in individual MSW test files; these are handled globally by `test_setup.js`.
- Add a handler for every GraphQL operation that fires during an MSW test; unhandled operations return 400.
- Place feature handler files in `handlers/` and register them in `handlers.js`.
- Use `assignRouter` from `test_helpers.js` to create a router; DO NOT call router factory functions directly or push routes manually.
- Use `loadFixturesMap` from `fixture_utils.js` to auto-load fixtures from a directory and map them to operation names by `camelCase` conversion.
- Add EE-suffixed or otherwise mismatched operation names to `OPERATION_NAME_OVERRIDES` in the handler file.
- Export new test helpers from `test_helpers.js` to make them available globally in all MSW integration tests (auto-imported via `Object.assign(global, testHelpers)` in `test_setup.js`).
- Name fixture files so that the `camelCase`-converted filename matches the GraphQL operation name (for example, `get_work_item_state_counts.query.graphql.json` maps to `getWorkItemStateCounts`).
- Place MSW integration fixture generators in `ee/spec/frontend/fixtures/`; generate their JSON output to `tmp/tests/frontend/fixtures-ee/graphql/` by running the fixture spec (`bin/rspec ee/spec/frontend/fixtures/<file>.rb`).
- Use `snapshotRequests` and `expectGraphQLCalls` from `operation_helpers.js` to assert Apollo cache integrity and verify that mutations do not trigger unwanted network calls.
- Run all MSW integration tests with `yarn jest:msw-integration`; in CI these run in the `jest-msw-integration` job.

### Capybara Feature Tests

- Add `:js` to specs or `describe` blocks that require JavaScript execution.
- Assert on a visible element before asserting on backend attributes to confirm the operation has completed; DO NOT use `wait_for_requests` to gate assertions — race conditions can occur when the wait is called before the request is made.
- Use Rails route helpers (for example, `project_pipeline_path`) instead of hardcoded URL strings.
- Stub feature flags explicitly in a `before do` block when testing the disabled state: `stub_feature_flags(my_feature_flag: false)`.
- DO NOT stub feature flags to `true`; they are enabled by default in the test environment.
- Use `expect_page_to_have_no_console_errors` in an `after` block to assert no unexpected browser console errors.
- Prefer `data-testid` selectors over CSS class selectors; use `.js-*` or CSS class selectors only as a last resort.
- Group back-to-back expectations using `:aggregate_failures`.

### Test Fixtures

- Import JSON/HTML fixtures using the `test_fixtures` alias.
- Generate fixtures with `bin/rake frontend:fixtures` or `bin/rspec spec/frontend/fixtures/<file>.rb` (see MSW Integration Tests for MSW-specific fixture generation).
- Place CE fixture generators in `spec/frontend/fixtures/` and EE fixture generators in `ee/spec/frontend/fixtures/`.

### Test Helpers

- Place new test helpers in `spec/frontend/__helpers__`.
- Use `testAction` helper (object argument form) for testing Vuex actions.
- Use `waitFor(url, callback)` or `waitForAll(callback)` from the Axios mock helper when no direct Promise handle is available.
- Use `shallowMountExtended` or `mountExtended` to access DOM Testing Library queries (`findByTestId`, `findByRole`, etc.) on VTU wrappers.

### Jest Timeout

- Eagerly import async-loaded modules in the spec file to force Jest to transpile and cache them at compile time, preventing runtime timeout errors.
- DO NOT disregard test timeouts; investigate whether the async import reflects a real production bundle issue.

## Authoritative sources

For the full picture, see:

- doc/development/testing_guide/frontend_testing.md

