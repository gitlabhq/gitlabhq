# Merge Request Guidelines

## Merge Request Description

If there are related issues, add their URLs to the description of the merge request under the heading `References`.

Add quick commands at the bottom of the description:

- Add a line with `/assign me` so the MR is assigned to the author.
- Add a line with `/milestone <milestone>` where the `<milestone>` corresponds to the milestone in the file `./VERSION`
  - For example, if `./VERSION` contains 18.11.0-pre, use the milestone `%18.11`.

## Pre-submission readiness checklist

Before opening a merge request, verify each predicate that applies to your change. Each item states the action; follow the linked detail for the how.

### Changelog

- Add a changelog trailer for any user-facing change, or explicitly decide it is unnecessary. Use the `--changelog` flag on `git commit` or add a `Changelog:` trailer.
- Detail: `.ai/principles/distilled/code-review.md` and `doc/development/changelog.md`.

### Tests

- Add or update tests for code changes. Recommended for documentation changes that ship code examples.
- Detail: `.ai/principles/distilled/qa-rspec.md` (backend, RSpec) and `.ai/principles/distilled/qa-jest.md` (frontend, Jest).

### Documentation

- Update documentation when behavior, API surface, configuration, or UI changes.
- Detail: `.ai/principles/distilled/documentation.md`.

### Screenshot

- Attach before/after screenshots for visible-UI changes.
- Detail: the "Images and Screenshots" and "Screenshot Guidelines" sections of `.ai/principles/distilled/documentation.md`.

### Application Security review

- Request Application Security review for changes touching authentication, session handling, dependency lockfiles, or other security-sensitive paths.
- Detail: `.ai/principles/distilled/security.md` and `.ai/principles/distilled/code-review.md`.

### Database review

- Request database review for migrations, schema changes, or query changes against large tables.
- Detail: `.ai/principles/distilled/database-fundamentals.md`, `.ai/principles/distilled/database-migrations.md`, and `.ai/principles/distilled/database-schema.md`.

### Translation

- Do not add hard-coded user-facing strings. Wrap them with the `_()`, `s_()`, or `n_()` externalization helpers (in JavaScript, `__()`, `s__()`, `n__()`) so they can be translated.
- Detail: `doc/development/i18n/externalization.md`.

### Feature flag

- Put non-trivial behavior changes behind a feature flag and define a rollout plan.
- Detail: `.ai/principles/distilled/feature-flags.md`.

### Milestone

- Set the milestone before merging, when the MR is likely to land in the current milestone.
- Detail: `.ai/principles/distilled/code-review.md` (Approval Requirements).

### MR type label

- Apply the correct MR type label (for example, `type::feature`, `type::bug`, `type::maintenance`).
- Detail: `.ai/principles/distilled/code-review.md` (Approval Requirements).
