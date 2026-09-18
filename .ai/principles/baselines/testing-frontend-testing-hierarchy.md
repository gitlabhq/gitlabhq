# Frontend Testing Hierarchy — Which Test to Write

> **Prerequisite:** Read `.ai/principles/distilled/testing-jest.md` first — it
> is the authoritative reference for *how* to write every test type covered
> here (unit, frontend integration, Capybara, fixtures).

This baseline answers only one question: **which kind of test to write**.

---

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
6. **Golden user journey** → End-to-end "golden journey" coverage against the full running application
  belongs to the QA suites in `qa/qa/specs/`.
5. **None of the above?** → Default to a unit test.

- DO NOT write a Capybara feature spec for a flow that is entirely
  frontend-rendered (Vue + GraphQL). Use a frontend integration test instead.
- DO NOT write a unit test for a multi-component interaction; use a frontend
  integration test so the real component tree is exercised.

### How to Write Each Test Type

See `.ai/principles/distilled/testing-jest.md` for the full how-to on all three
layers: unit/component tests, frontend integration tests, and Capybara feature
tests.

For MSW-specific additions not covered in `testing-jest.md` (run command, handler
registration pattern, GraphQL request counting), see
`.ai/principles/distilled/testing-msw.md`.
