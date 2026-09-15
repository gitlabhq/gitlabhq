---
source_checksum: 7bd637aa5683624c
distilled_at_sha: da75f7373628b035becb13fb3f0d21b4b3d3690f
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# MSW Integration Tests Principles

## Checklist

### When to Use MSW Integration Tests

- Use an MSW integration test (`ee/spec/frontend/msw_integration/`, EE-only) when the test covers multi-component interaction on a single page, backend responses can be represented with auto-generated fixtures, and you do not need to verify database state, authorization, server-side validations, or real-time updates.
- Use a Capybara feature test (`spec/features/`) instead when the test requires a real backend (database writes, authorization checks, server-side validations), navigation across multiple server-rendered pages, backend state not representable with fixtures, or behavior that depends on multiple Vue applications on the same page.

### Location (EE-only)

- Place all MSW integration specs and harness files under
  `ee/spec/frontend/msw_integration/`. The CE path
  `spec/frontend/msw_integration/` is intentionally empty and blocked by ESLint.
- DO NOT add MSW integration tests for FOSS-versus-licensed behavior; MSW mocks
  the network layer (including auth and licensing) and cannot assert those
  differences. Use a Capybara feature spec instead.

### Running MSW Integration Tests

- Run with `yarn jest:msw-integration`; DO NOT run with the default `yarn jest`.

### Directory Structure

- Use the shared files (`handlers.js`, `server.js`, `test_setup.js`, `polyfills.js`, `test_helpers.js`) configured automatically through `jest.config.msw_integration.js`; DO NOT duplicate their setup in individual test files.

### Handler Registration

- Place a feature's handlers in a per-feature subdirectory module
  (e.g. `work_items/handlers.js`) and register them in the top-level
  `handlers.js` via `featureHandlers`/`restEndpoints`.
- Export new test helpers from `test_helpers.js` so they are available
  globally in all MSW integration tests (auto-imported via
  `Object.assign(global, testHelpers)` in `test_setup.js`).
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

### Fixture Variants

- Declare named fixture variants instead of editing handlers when testing a different response shape (error, empty list, flipped flag); place the variant file at `ee/spec/frontend/msw_integration/<feature>/fixture_variants/<query>.js` and call `defineFixtureVariants({ query, variants })` as its default export.
- Use `BASE` as the required default variant key; `BASE` is served unless a test activates another variant.
- Build variants with the three transform helpers from `fixture_utils.js` — `setFixtureData(fixture, lookupKey, value)`, `setFixtureErrors(fixture, ['message'])`, and `setFixtureItemsCount({ fixture, lookupKey, itemCount })` — each deep-clones its input; DO NOT clone or mutate the imported fixture directly.
- Activate a variant in a test with `setQueryVariant('operationName', 'VARIANT_KEY')` imported from `ee_jest/msw_integration/setup_utils`; the active variant resets to `BASE` automatically in `afterEach`.
- Generate a manifest of all registered queries and variant keys with `yarn msw:variants` (writes to `tmp/tests/frontend/msw_variants.manifest.json`); DO NOT commit the manifest.

### Assert Apollo Cache Integrity

- Use `snapshotRequests()` before an action and `expectGraphQLCalls(baseline, { expect, forbid })` inside `waitFor` after the action to verify that mutations update the Apollo cache without triggering unwanted network calls; import both from `ee_jest/msw_integration/operation_helpers`.
- DO NOT match two `snapshotRequests` calls without using `expectGraphQLCalls` — `expectGraphQLCalls` throws a Jest diff on unexpected calls, making debugging easier.
- Reset `capturedRequests` manually in your own test suite if stray operations fire after the global `afterEach` reset has already been called.

### Mounting

- If a feature suite provides its own mount helper in `test_support/`, use
  that instead of calling `fullMount` directly. The helper wires in the
  feature's required configuration and provide values, which `fullMount`
  alone does not know about.
- Feature mount helpers must wrap `fullMount`, not replace it. DO NOT
  reimplement mounting logic in a feature helper, and DO NOT mount with
  `shallowMountExtended` or `mountExtended`.
- Example: the AI Duo Panel suite's `mountAISidebar` and
  `mountDuoAgenticChatStateManager` (in
  `ee/spec/frontend/msw_integration/ai_duo_panel/test_support/`) both call
  `fullMount` internally. See that suite's README for when to use each one.

### Write a Test File

- Create a router with `assignRouter` from `test_helpers.js` instead of calling the router factory directly, so `test_setup.js` can reset it between tests; DO NOT push routes manually.
- Mount the root component with `fullMount` from `test_helpers.js` and the real `apolloProvider`; DO NOT use `shallowMountExtended` or `mountExtended` in MSW integration tests.
- Use `waitFor` from `@testing-library/dom` after actions that trigger API calls.
- Reset the Apollo cache in `beforeEach` with `apolloProvider.defaultClient.cache.reset()` to prevent state leaking between tests.
- DO NOT add `afterEach` cleanup for wrapper destruction or Apollo client teardown — the global `test_setup.js` handles router resets, wrapper destroy, and metadata cleanup.
- DO NOT add `server.listen`, `server.resetHandlers`, or `server.close` calls in individual test files — server lifecycle is handled globally by `test_setup.js`.
- DO NOT mock child components in MSW integration tests; the goal is to test how components work together.

### Finding Elements & Interactions

- Use `@testing-library/vue` queries to locate elements
- Drive navigation and state changes through user-facing UI actions (click the link or button); DO NOT push routes or call component methods to get the app into a state.
- DO NOT spy on or assert against component internals (methods, computed props); assert against rendered output instead.

### DOM Assertions (Vue-Agnostic)

- After mounting, interact with and assert on the DOM using native DOM APIs; DO NOT use Vue Test Utils wrapper methods (`wrapper.find()`, `wrapper.findComponent()`, `wrapper.trigger()`, `wrapper.text()`, `wrapper.exists()`) in MSW integration tests.
- DO NOT access `vm.$emit()`, `vm.$data`, or any component instance property; DO NOT use `el.__vue__` or `createWrapper()` to obtain a VTU wrapper from a DOM element.
- Use native DOM equivalents: `.querySelector(selector)` instead of `.find(selector)`, `.click()` instead of `.trigger('click')`, `getText(el)` from `test_helpers.js` instead of `.text()`, `.getAttribute('name')` instead of `.attributes('name')`, `!== null` instead of `.exists()`.

## Authoritative sources

For the full picture, see:

- doc/development/testing_guide/frontend_testing.md

