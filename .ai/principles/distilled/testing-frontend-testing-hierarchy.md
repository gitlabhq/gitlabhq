---
source_checksum: 716050a148887026
distilled_at_sha: eca2a8965486ff4e057e946be5b7c02f8b067138
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Frontend Testing Hierarchy Principles

## Checklist

### Test Type Decision

Use this decision order. Stop at the first match.

1. **Single Vue component in isolation?** → Unit/component test in
   `spec/frontend/` using Jest.
2. **Full page or Vue app with GraphQL (multiple components working together)?**
   → frontend integration test in `ee/spec/frontend/integration/`.
3. **HAML template with no frontend logic?** → Skip frontend tests entirely;
   rely on the existing Rails view spec.
4. **Needs real DB, auth, session, or cross-page navigation?** → Capybara
   feature spec in `spec/features/`.
5. **Golden user journey** → End-to-end "golden journey" coverage against the full running application
   belongs to the QA suites in `qa/qa/specs/`.
6. **None of the above?** → Default to a unit test.

- DO NOT write a Capybara feature spec for a flow that is entirely
  frontend-rendered (Vue + GraphQL). Use a frontend integration test instead.
- DO NOT write a unit test for a multi-component interaction; use a frontend
  integration test so the real component tree is exercised.

### How to Write Each Test Type

See `.ai/principles/distilled/testing-jest.md` for the full how-to on all three
layers: unit/component tests, frontend integration tests, and Capybara feature
tests.

For frontend integration setup, handlers, fixtures, and request counting, see
[Frontend integration tests](https://docs.gitlab.com/development/testing_guide/frontend_testing/#frontend-integration-tests).

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

- Use a frontend integration test (`ee/spec/frontend/integration/`, EE-only) when the test covers multi-component interaction on a single page and backend responses can be represented with fixtures, including recorded unlicensed payloads. Use a Capybara feature test (`spec/features/`) when the test requires database state, authorization, server-side validations, real-time updates, backend license enforcement, cross-page navigation, backend state not representable with fixtures, or multiple Vue applications on the same page.
- Add `:js` metadata to RSpec feature specs that require JavaScript; DO NOT omit it when the test depends on JavaScript execution.
- Before asserting on backend attributes in a Capybara spec, assert on a visible page element first to confirm the operation completed; DO NOT use `wait_for_requests` as a substitute (race conditions can occur).

### Test File Placement

- Place Jest unit and component tests in `spec/frontend/`; place frontend integration tests in `ee/spec/frontend/integration/` (EE-only — adding any file under `spec/frontend/integration/` fails ESLint); place Capybara feature tests in `spec/features/`.
- Place EE-specific tests under the `ee/spec` folder following the same structure.

## Authoritative sources

For the full picture, see:

- doc/development/testing_guide/frontend_testing.md
- doc/development/testing_guide/testing_levels.md
