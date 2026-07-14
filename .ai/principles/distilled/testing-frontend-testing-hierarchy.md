---
source_checksum: a26b2155e11ee01a
distilled_at_sha: f22602e37afb92eb7028b601a922ebde417df6e4
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Frontend Testing Hierarchy Principles

## Checklist

### Test Type Decision

Use this decision order. Stop at the first match.

1. **Single Vue component in isolation?** → Unit/component test in
   `spec/frontend/` using Jest.
2. **Full page or Vue app with GraphQL (multiple components working together)?**
   → MSW integration test in `spec/frontend/msw_integration/`.
3. **HAML template with no frontend logic?** → Skip frontend tests entirely;
   rely on the existing Rails view spec.
4. **Needs real DB, auth, session, or cross-page navigation?** → Capybara
   feature spec in `spec/features/`.
5. **Golden user journey** → End-to-end "golden journey" coverage against the full running application
   belongs to the QA suites in `qa/qa/specs/`.
6. **None of the above?** → Default to a unit test.

- DO NOT write a Capybara feature spec for a flow that is entirely
  frontend-rendered (Vue + GraphQL). Use an MSW integration test instead.
- DO NOT write a unit test for a multi-component interaction; use an MSW
  integration test so the real component tree is exercised.

### How to Write Each Test Type

See `.ai/principles/distilled/testing-jest.md` for the full how-to on all three
layers: unit/component tests, MSW integration tests, and Capybara feature
tests.

For MSW-specific additions not covered in `testing-jest.md` (run command, handler
registration pattern, GraphQL request counting), see
`.ai/principles/distilled/testing-msw.md`.

### Unit Tests

- Write unit tests for exported functions, classes, Vuex actions, and complex Vuex mutations; DO NOT write unit tests for non-exported functions, constants, or Vue computed properties/methods (they are implementation details covered implicitly by component tests).
- DO NOT test library internals (for example, Vue computed properties that merely delegate to a library); test the rendered template output instead.
- DO NOT assert on `wrapper.vm` properties — test the rendered template to reflect how a user perceives the component.
- Mock all server requests, other exported classes, and asynchronous background operations in unit tests; DO NOT mock non-exported functions, methods of the class under test, or pure utility functions.
- DO NOT load full HTML pages in unit tests — create single DOM elements when the test only operates on them.

### Component Tests

- Use component tests for individual Vue components only; DO NOT use them for full Vue applications (use frontend integration tests instead) or HAML templates (which contain no frontend logic).
- Mock side effects (network requests) and child components in component tests; DO NOT mock methods or computed properties of the component under test, and DO NOT mock Vuex — set Vuex state via mutations and mock only side effects.

### Integration Tests (Frontend)

- Use frontend integration tests for page bundles (`index.js` files in `app/assets/javascripts/pages/`) and Vue applications outside page bundles.
- Use HAML fixtures (not rendered HAML) in integration tests; mock all server requests and non-perceivable background operations.
- DO NOT mock the DOM, component properties/state, or Vuex stores in integration tests — test on the real DOM and let the full component tree interact.

### Feature Tests (Frontend)

- Use feature tests only when the use case requires a real backend and cannot be covered with fixtures, or when behavior is defined globally rather than in a page bundle.
- Add `:js` metadata to RSpec feature specs that require JavaScript; DO NOT omit it when the test depends on JavaScript execution.
- Prefer MSW integration tests over Capybara feature tests whenever the backend is not strictly required — Capybara tests are significantly slower.
- Before asserting on backend attributes in a Capybara spec, assert on a visible page element first to confirm the operation completed; DO NOT use `wait_for_requests` as a substitute (race conditions can occur).

### Test File Placement

- Place Jest unit, component, and integration tests in `spec/frontend/`; place MSW integration tests in `spec/frontend/msw_integration/`; place Capybara feature tests in `spec/features/`.
- Place EE-specific tests under the `ee/spec` folder following the same structure.

## Authoritative sources

For the full picture, see:

- doc/development/testing_guide/frontend_testing.md
- doc/development/testing_guide/testing_levels.md

