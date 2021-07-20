---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Renaming features

Sometimes the business asks to change the name of a feature. Broadly speaking, there are 2 approaches to that task. They basically trade between immediate effort and future complexity/bug risk:

- Complete, rename everything in the repository.
  - Pros: does not increase code complexity.
  - Cons: more work to execute, and higher risk of immediate bugs.
- Façade, rename as little as possible; only the user-facing content like interfaces,
  documentation, error messages, and so on.
  - Pros: less work to execute.
  - Cons: increases code complexity, creating higher risk of future bugs.

## When to choose the façade approach

The more of the following that are true, the more likely you should choose the façade approach:

- You are not confident the new name is permanent.
- The feature is susceptible to bugs (large, complex, needing refactor, etc).
- The renaming is difficult to review (feature spans many lines, files, or repositories).
- The renaming is disruptive in some way (database table renaming).

## Consider a façade-first approach

The façade approach is not necessarily a final step. It can (and possibly *should*) be treated as the first step, where later iterations accomplish the complete rename.
