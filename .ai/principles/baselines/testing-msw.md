# MSW Integration Tests — How to Write Them

> **Prerequisite:** Read `.ai/principles/distilled/testing-jest.md` first — its
> **MSW Integration Tests**, **Capybara Feature Tests**, and **Test Fixtures**
> sections are the primary reference and apply in full here.

This baseline covers only the gaps and additions not already in `testing-jest.md`.
For the decision of *which* test type to write, see
`.ai/principles/distilled/testing-frontend-testing-hierarchy.md`.

---

## Checklist

### Running MSW Integration Tests

- Run with `yarn jest:msw-integration`; DO NOT run with the default `yarn jest`.

### Handler Registration

- Place a feature's handlers in a per-feature subdirectory module
  (e.g. `work_items/handlers.js`) and register them in the top-level
  `handlers.js` via `featureHandlers`/`restEndpoints`.
- Export new test helpers from `test_helpers.js` so they are available
  globally in all MSW integration tests (auto-imported via
  `Object.assign(global, testHelpers)` in `test_setup.js`).

### Finding Elements & Interactions

- Use `@testing-library/vue` queries to locate elements
- Drive navigation and state changes through user-facing UI actions (click
  the link or button); DO NOT push routes or call component methods to get
  the app into a state.
- DO NOT spy on or assert against component internals (methods, computed
  props); assert against rendered output instead.
