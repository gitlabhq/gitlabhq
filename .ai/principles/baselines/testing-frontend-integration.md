# Frontend Integration Tests — How to Write Them

> **Prerequisite:** Read `.ai/principles/distilled/testing-jest.md` first — its
> **Frontend Integration Tests**, **Capybara Feature Tests**, and **Test Fixtures**
> sections are the primary reference and apply in full here.

This baseline covers only the gaps and additions not already in `testing-jest.md`.
For the decision of *which* test type to write, see
`.ai/principles/distilled/testing-frontend-testing-hierarchy.md`.

---

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
