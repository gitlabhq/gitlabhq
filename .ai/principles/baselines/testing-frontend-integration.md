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
- Prefer `screen.queryByTestId('foo')` and `screen.queryAllByTestId('foo')` over
  `document.querySelector('[data-testid="foo"]')` and
  `document.querySelectorAll('[data-testid="foo"]')`; `screen` is available from
  `@testing-library/vue` and the suite's `test_helpers.js`
- Prefer role/label queries (`screen.queryByRole`, `screen.queryByLabelText`)
  for one-shot assertions — they match the way users and assistive technology
  find elements, so they double as an accessibility check (see the
  [query priority guide](https://testing-library.com/docs/queries/about/#priority))
- DO NOT poll an unscoped role query (`waitForElement`/`waitFor` +
  `screen.queryByRole` on the full tree). `ByRole` computes visibility and an
  accessible name for every candidate on every poll tick, which is cripplingly
  slow in a `fullMount`. Address the container by test ID and query the role
  inside it, with a null guard because `within(null)` throws:
  `const form = screen.queryByTestId('x'); return form ? within(form).queryByRole(…) : null;`
- Scoping queries with `within()` to the region under test is good practice
  for any query type in a full mount, but DO NOT scope past a portal boundary
  (`GlModal`, dropdowns, and tooltips render outside their parent) — query
  portaled content from `screen`
- DO NOT key finders off an accessible name that changes with state (for
  example, a toggle that relabels itself): a copy change reads as "element
  missing" instead of "label changed". Address the element by test ID once and
  read state from ARIA attributes (`aria-pressed`, and so on)
- `querySelector` remains acceptable for scoping a search inside an
  already-found element, and for selectors Testing Library cannot express
  (class or ID selectors)
- Drive navigation and state changes through user-facing UI actions (click
  the link or button); DO NOT push routes or call component methods to get
  the app into a state.
- DO NOT spy on or assert against component internals (methods, computed
  props); assert against rendered output instead.
