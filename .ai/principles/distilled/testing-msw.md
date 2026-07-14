---
source_checksum: 635b68d02ba3f98e
distilled_at_sha: f22602e37afb92eb7028b601a922ebde417df6e4
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# MSW Integration Tests Principles

## Checklist

### When to Use MSW Integration Tests

- Use an MSW integration test (`spec/frontend/msw_integration/`) when the test covers multi-component interaction on a single page, backend responses can be represented with auto-generated fixtures, and you do not need to verify database state, authorization, server-side validations, or real-time updates.
- Use a Capybara feature test (`spec/features/`) instead when the test requires a real backend (database writes, authorization checks, server-side validations), navigation across multiple server-rendered pages, backend state not representable with fixtures, or behavior that depends on multiple Vue applications on the same page.

### Running MSW Integration Tests

- Run with `yarn jest:msw-integration`; DO NOT run with the default `yarn jest`.

### Directory Structure

- Place MSW integration test files under `spec/frontend/msw_integration/` in a subdirectory mirroring the feature area (e.g. `work_items/work_item_spec.js`).
- Use the shared files (`handlers.js`, `server.js`, `test_setup.js`, `polyfills.js`, `test_helpers.js`) configured automatically through `jest.config.msw_integration.js`; DO NOT duplicate their setup in individual test files.
- Export new test helpers from `test_helpers.js` so they are available globally in all MSW integration tests (auto-imported via `Object.assign(global, testHelpers)` in `test_setup.js`).

### Handler Registration

- Place a feature's handlers in a per-feature subdirectory module (e.g. `work_items/handlers.js`) and register them in the top-level `handlers.js` via `featureHandlers`/`restEndpoints`.
- Register one `rest.post` handler for `http://test.host/api/graphql` in `handlers.js` as a thin GraphQL router that delegates to feature-specific resolver functions in order; DO NOT split a single GraphQL endpoint across multiple MSW handlers.
- Ensure every GraphQL operation that fires during a test has a corresponding handler; unhandled operations fall through to a catch-all that returns a 400 status — if a test fails with `ServerParseError: Unexpected end of JSON input`, add the missing operation to the relevant feature handler file.
- Have each feature resolver receive `{ operationName, variables, res, ctx }` and return an MSW response if it handles the operation, or `null` to pass to the next resolver.

### Adding a New Feature Domain

- Create a resolver file in `handlers/` that uses `loadFixturesMap` to auto-load fixtures and build the handler.
- Register the new resolver in `handlers.js` by importing it and adding it to `graphqlFeatureHandlers`.
- Generate fixtures by adding an RSpec spec in `ee/spec/frontend/fixtures/` and running it (see Generate Fixtures).

### Generate Fixtures

- Generate MSW integration fixtures by running the RSpec fixture spec (e.g. `bundle exec rspec ee/spec/frontend/fixtures/work_items_integration.rb`); DO NOT hand-write JSON fixture files.
- Add a new fixture by adding a new `it` block to the fixture generator spec — the test name determines the output file path (e.g. `"graphql/work_items/integration/my_query.query.graphql.json"`).
- Follow the fixture naming convention: name fixture files in `snake_case` matching the GraphQL operation name after `camelCase` conversion (e.g. `get_work_item_state_counts.query.graphql.json` maps to operation `getWorkItemStateCounts`).

### Write Feature Handlers

- Use `loadFixturesMap` from `fixture_utils.js` to automatically load all JSON fixtures from a directory and map them to `camelCase` operation name keys; DO NOT manually import each fixture file.
- Add an entry to `OPERATION_NAME_OVERRIDES` in the handler file for any operation name that does not match the derived `camelCase` filename (e.g. EE-suffixed operations like `getWorkItemsFullEE`).
- Spread auto-loaded `fixtures` and `OPERATION_NAME_OVERRIDES` into `FIXTURE_RESPONSES`; use `MUTATION_OPERATION_HANDLERS` for mutations that need dynamic responses based on input variables.
- Combine static and mutation handlers into a single `OPERATION_HANDLERS` map and look up the operation in the resolver function.

### Assert Apollo Cache Integrity

- Use `snapshotRequests()` before an action and `expectGraphQLCalls(baseline, { expect, forbid })` inside `waitFor` after the action to verify that mutations update the Apollo cache without triggering unwanted network calls.
- DO NOT match two `snapshotRequests` calls without using `expectGraphQLCalls` — `expectGraphQLCalls` throws a Jest diff on unexpected calls, making debugging easier.
- Reset `capturedRequests` manually in your own test suite if stray operations fire after the global `afterEach` reset has already been called.

### Write a Test File

- Create a router with `assignRouter` from `test_helpers.js` instead of calling the router factory directly, so `test_setup.js` can reset it between tests; DO NOT push routes manually.
- Mount the root component with `fullMount` from `test_helpers.js` and the real `apolloProvider`; DO NOT use `shallowMountExtended` or `mountExtended` in MSW integration tests.
- Use `waitFor` from `@testing-library/dom` after actions that trigger API calls.
- Reset the Apollo cache in `beforeEach` with `apolloProvider.defaultClient.cache.reset()` to prevent state leaking between tests.
- DO NOT add `afterEach` cleanup for wrapper destruction or Apollo client teardown — the global `test_setup.js` handles router resets, wrapper destroy, and metadata cleanup.
- DO NOT add `server.listen`, `server.resetHandlers`, or `server.close` calls in individual test files — server lifecycle is handled globally by `test_setup.js`.
- DO NOT mock child components in MSW integration tests; the goal is to test how components work together.

### Finding Elements & Interactions

- Use `@testing-library/vue` queries to locate elements.
- Drive navigation and state changes through user-facing UI actions (click the link or button); DO NOT push routes or call component methods to get the app into a state.
- DO NOT spy on or assert against component internals (methods, computed props); assert against rendered output instead.

### DOM Assertions (Vue-Agnostic)

- After mounting, interact with and assert on the DOM using native DOM APIs; DO NOT use Vue Test Utils wrapper methods (`wrapper.find()`, `wrapper.findComponent()`, `wrapper.trigger()`, `wrapper.text()`, `wrapper.exists()`) in MSW integration tests.
- DO NOT access `vm.$emit()`, `vm.$data`, or any component instance property; DO NOT use `el.__vue__` or `createWrapper()` to obtain a VTU wrapper from a DOM element.
- Use native DOM equivalents: `.querySelector(selector)` instead of `.find(selector)`, `.click()` instead of `.trigger('click')`, `getText(el)` from `test_helpers.js` instead of `.text()`, `.getAttribute('name')` instead of `.attributes('name')`, `!== null` instead of `.exists()`.

## Authoritative sources

For the full picture, see:

- doc/development/testing_guide/frontend_testing.md

