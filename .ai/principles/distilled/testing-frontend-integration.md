---
source_checksum: 01eda961cda9d6f6
distilled_at_sha: eca2a8965486ff4e057e946be5b7c02f8b067138
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Frontend Integration Tests Principles

## Checklist

### Location (EE-only)

- Place all frontend integration specs and harness files under
  `ee/spec/frontend/integration/`. The CE path
  `spec/frontend/integration/` is intentionally empty and blocked by ESLint.
- DO NOT use frontend integration tests to verify backend license enforcement;
  MSW intercepts the network requests. Use Capybara for enforcement tests.
  Exception: use frontend integration tests to verify rendering of recorded
  unlicensed payloads.

### Running Frontend Integration Tests

- Run with `yarn jest:integration`; DO NOT run with the default `yarn jest`.

### Handler Registration

- Place a feature's handlers in a per-feature subdirectory module
  (e.g. `work_items/handlers.js`) and register them in the top-level
  `handlers.js` via `featureHandlers`/`restEndpoints`.
- Export new test helpers from `test_helpers.js` so they are available
  globally in all frontend integration tests (auto-imported via
  `Object.assign(global, testHelpers)` in `test_setup.js`).

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
  `ee/spec/frontend/integration/ai_duo_panel/test_support/`) both call
  `fullMount` internally. See that suite's README for when to use each one.

### Finding Elements & Interactions

- Use `@testing-library/vue` queries to locate elements
- Drive navigation and state changes through user-facing UI actions (click
  the link or button); DO NOT push routes or call component methods to get
  the app into a state.
- DO NOT spy on or assert against component internals (methods, computed
  props); assert against rendered output instead.

### Handler Architecture

- Register a single `graphql.operation` handler in `handlers.js` as a thin GraphQL router that delegates to feature-specific resolver functions in order; DO NOT split a single GraphQL endpoint across multiple MSW handlers.
- Ensure every GraphQL operation that fires during a test has a corresponding handler; unhandled operations are recorded and answered with a 400 status — at the end of the suite a `console.warn` lists every missing operation; use that list to add the missing operation to the relevant feature handler file.
- Have each feature resolver receive `{ operationName, variables }` and return an MSW response if it handles the operation, or `null` to pass to the next resolver.
- Declare REST endpoints as plain descriptor objects (`{ method, path, response }`) and set `name` to control the key requests are captured under; a trailing `http.get('*')` handler catches any unmocked GET request and returns a 400.

### Adding a New Feature Domain

- Create a `<feature>/handlers.js` file that uses `loadFixturesMap` to auto-load fixtures and build the handler; register the resolver in the top-level `handlers.js` by importing it and adding it to `featureHandlers` and `restEndpoints`.
- Generate fixtures by adding an RSpec spec in `ee/spec/frontend/fixtures/` and running it (see Generate Fixtures).

### Generate Fixtures

- Generate integration fixtures by running the RSpec fixture spec (e.g. `bundle exec rspec ee/spec/frontend/fixtures/work_items_integration.rb`); DO NOT hand-write JSON fixture files.
- Add a new fixture by adding a new `it` block to the fixture generator spec — the test name determines the output file path (e.g. `"graphql/work_items/integration/my_query.query.graphql.json"`).
- Follow the fixture naming convention: name fixture files in `snake_case` matching the GraphQL operation name after `camelCase` conversion (e.g. `get_work_item_state_counts.query.graphql.json` maps to operation `getWorkItemStateCounts`).

### Write Feature Handlers

- Use `loadFixturesMap` from `fixture_utils.js` to automatically load all JSON fixtures from a directory and map them to `camelCase` operation name keys; DO NOT manually import each fixture file.
- Add an entry to `OPERATION_NAME_OVERRIDES` in the handler file for any operation name that does not match the derived `camelCase` filename (e.g. EE-suffixed operations like `getWorkItemsFullEE`).
- Spread auto-loaded `fixtures` and `OPERATION_NAME_OVERRIDES` into `FIXTURE_RESPONSES`; use `MUTATION_OPERATION_HANDLERS` for mutations that need dynamic responses based on input variables.
- Combine static and mutation handlers into a single `OPERATION_HANDLERS` map and look up the operation in the resolver function.

### Fixture Variants

- Declare named fixture variants instead of editing handlers when testing a different response shape (error, empty list, flipped flag); place the variant file at `ee/spec/frontend/integration/<feature>/fixture_variants/<query>.js` and call `defineFixtureVariants({ query, variants })` as its default export.
- Use `BASE` as the required default variant key; `BASE` is served unless a test activates another variant.
- Build variants with the three transform helpers from `fixture_utils.js` — `setFixtureData(fixture, lookupKey, value)`, `setFixtureErrors(fixture, ['message'])`, and `setFixtureItemsCount({ fixture, lookupKey, itemCount })` — each deep-clones its input; DO NOT clone or mutate the imported fixture directly.
- Import the variant file as a side-effect import in the feature handler (e.g. `import './fixture_variants/my_query';`), not in the spec — `setQueryVariant` throws `"expected a query constant"` and `activateVariant` throws `"no variants registered for query"` if the variant file has not been imported.
- Activate a variant in a test with `setQueryVariant(queryConstant).variantMethod()` imported from `ee_jest/integration/helpers/setup_utils`; the active variant resets to `BASE` automatically in `afterEach`. When the variant key is a runtime value, use the low-level `activateVariant('operationName', variantKey)` instead.
- In the feature handler, use `getActiveVariant('operationName') ?? defaultFixture` to serve the active variant; `getActiveVariant` returns `null` for `BASE` (not the `BASE` fixture), so the `??` fallback serves the handler's own default. Prefer `??` over `||`.
- DO NOT declare the same `query` name in two different variant files — `defineFixtureVariants` throws `"variants for query X are already registered"` if the same query is registered twice; keep one variant file per query.
- Generate a manifest of all registered queries and variant keys with `yarn integration:variants` (writes to `tmp/tests/frontend/integration_variants.manifest.json`); DO NOT commit the manifest.

### Test Unlicensed Feature States

- Record an unlicensed payload by calling `stub_licensed_features` inside the individual `it` block, merging the target feature off onto the existing `licensed_features` set (e.g. `stub_licensed_features(licensed_features.merge(work_item_status: false))`); DO NOT pass a bare hash with only the single feature — that turns every other licensed feature off too.
- Register the recorded unlicensed fixture as a named variant in the query's variant file rather than mutating or stripping down the base fixture with a transform helper; a recording proves what Rails actually returns for an unlicensed namespace.
- Activate the variant in the spec and pair every negative assertion (feature absent) with a positive assertion (a sibling element rendered) to prevent false positives.
- When a scenario needs several features unlicensed at once, record that combination as one fixture and register it as a single variant; queries that are separate operations can each have their own active variant.
- Confirm which handler branch your query takes when a handler branches on a request variable, and register the variant under the operation key that branch reads.
- Ensure every response feeding the same Apollo-cached entity has the unlicensed shape so another list or REST response cannot restore missing data.

### Assert Apollo Cache Integrity

- Use `snapshotRequests()` before an action and `expectGraphQLCalls(baseline, { expect, forbid })` inside `waitFor` after the action to verify that mutations update the Apollo cache without triggering unwanted network calls; import both from `ee_jest/integration/core/operation_helpers`.
- DO NOT match two `snapshotRequests` calls without using `expectGraphQLCalls` — `expectGraphQLCalls` throws a Jest diff on unexpected calls, making debugging easier.
- Use `lastRequestVariables(operationName)` to assert that the correct filter variables were sent; it throws if the operation was never called.
- Reset `capturedRequests` manually in your own test suite if stray operations fire after the global `afterEach` reset has already been called.

### Write a Test File

- Create a router with `assignRouter` from `test_helpers.js` instead of calling the router factory directly, so `test_setup.js` can reset it between tests; DO NOT push routes manually.
- Mount the root component with `fullMount` from `test_helpers.js` and the real `apolloProvider`; DO NOT use `shallowMountExtended` or `mountExtended` in frontend integration tests.
- Use `waitFor` from `@testing-library/dom` after actions that trigger API calls.
- Reset the Apollo cache in `beforeEach` with `apolloProvider.defaultClient.cache.reset()` to prevent state leaking between tests; `test_setup.js` calls `clearMountedApolloStores()` in `beforeEach` to cancel in-flight fetches before each test, so spec files do not need to do anything extra beyond the usual `cache.reset()`.
- DO NOT add `afterEach` cleanup for wrapper destruction or Apollo client teardown — the global `test_setup.js` handles router resets, wrapper destroy, and metadata cleanup.
- DO NOT add `server.listen`, `server.resetHandlers`, or `server.close` calls in individual test files — server lifecycle is handled globally by `test_setup.js`.
- DO NOT mock child components in frontend integration tests; the goal is to test how components work together.

### DOM Assertions (Vue-Agnostic)

- After mounting, interact with and assert on the DOM using native DOM APIs; DO NOT use Vue Test Utils wrapper methods (`wrapper.find()`, `wrapper.findComponent()`, `wrapper.trigger()`, `wrapper.text()`, `wrapper.exists()`) in frontend integration tests.
- DO NOT access `vm.$emit()`, `vm.$data`, or any component instance property; DO NOT use `el.__vue__` or `createWrapper()` to obtain a VTU wrapper from a DOM element.
- Use native DOM equivalents: `.querySelector(selector)` instead of `.find(selector)`, `.click()` instead of `.trigger('click')`, `getText(el)` from `test_helpers.js` instead of `.text()`, `.getAttribute('name')` instead of `.attributes('name')`, `!== null` instead of `.exists()`.

## Authoritative sources

For the full picture, see:

- doc/development/testing_guide/frontend_testing.md
