# Git workflow rules

Before creating any branch or commit, or adding changelog entries, validate against all rules in this file.

## Branch naming rules

Allowed characters: lowercase letters, numbers, hyphens (`-`), underscores (`_`). No spaces. No uppercase.

Use these default patterns unless a different name is specified:

- `feature/<description>` for new features
- `fix/<description>` for bug fixes
- `docs/<description>` for documentation-only changes
- `docs-<description>` for documentation-only changes (alternative)
- `refactor/<description>` for code refactoring
- `<issue-number>-<description>` for issue-linked changes
- `<issue-number>-<description>-docs` for issue-linked documentation changes

Do not use 40-character hexadecimal strings (these conflict with Git commit hashes).

Documentation branches (`docs/` or `docs-` prefix, or `-docs` suffix) trigger faster CI pipelines. Use them for documentation-only changes.

## Commit message rules

### Subject line (required)

1. 72 characters maximum
1. Start with a capital letter
1. No period at the end
1. Minimum 3 words
1. Imperative mood: "Add feature", not "Added feature"
1. No emojis

Allowed prefixes: `[API]`, `danger:`, and similar category prefixes are permitted before the subject.

### Body (conditional)

Required when the commit changes 30 or more lines across 3 or more files.

If a body is included:

- Separate from subject with one blank line
- 72 characters maximum per line
- Explain why the change is being made, not what it does

### Issue and MR references

Use full URLs. Do not use short references.

- Correct: `Resolves https://gitlab.com/gitlab-org/gitlab/-/issues/123456`
- Incorrect: `Resolves #123456`

This applies to merge request titles and descriptions as well, not only
commit messages. Danger scans the MR description and fails when it finds
short references such as `!123`, `#123`, `group/project#123`, or `%12.3`,
because they render as plain text outside GitLab.

## Commit trailers

Do not add `Co-Authored-By:` trailers to commit messages.

## Changelog rules

Add `Changelog: <type>` as the last line of the commit message body.

`added`, `fixed`, `changed`, `deprecated`, `removed`, `security`, `performance`, `other`

For EE-only changes, add `EE: true` on a separate line after the changelog entry.

### When to include

- User-facing changes
- API changes
- Breaking changes
- Security fixes
- Database migrations

### When to skip

- Internal refactoring only
- Test-only changes
- Documentation-only changes
- Development tooling changes

### Feature flag changelog

| Scenario | Changelog type |
|----------|---------------|
| Removing default-off flag, keeping the new feature | `added` / `changed` / `fixed` (describe the feature) |
| Removing default-off flag, removing the new feature (rollback) | `other` |
| Removing default-on flag, keeping the new feature (cleanup) | `other` |
| Removing default-on flag, reverting to old behavior | `removed` / `changed` |

## Commit granularity

Each commit should represent one coherent concern with a single review context and a clean rollback profile. A reviewer should be able to evaluate a commit without needing to understand changes in sibling commits.

When a change spans multiple concern types, split proactively before the first commit — not after a reviewer flags it. Common concern boundaries:

| Concern | What it contains |
|---|---|
| Documentation | `*.md` files (README, guides, changelogs), API docs — standalone doc-only changes, or docs that accompany a code change but are independently reviewable |
| Database schema | Migration files — always isolated; never bundle migrations with unrelated feature code in the same commit |
| Implementation | The functional change: models, services, API endpoints, Vue components, business logic |
| Tests | RSpec/Jest specs for the implementation — travel with the implementation commit unless the suite is large enough to warrant a dedicated commit |
| Tooling / scripts | Shell scripts, CI pipeline config, build tooling, linting rules, `package.json` scripts — anything that changes how the project is built, linted, or run |
| Wiring / integration | Connecting new code to existing entry points: routes, feature flag checks, initializers, registry entries, Rake tasks |

These are not mechanical rules — use judgment. The test: could this commit be reverted independently without breaking the others? If not, it should probably be split further.

## Integration workflow

### Rebase, not merge
When integrating parallel stream branches into an integration branch, use `git rebase` rather than `git merge`. Rebase produces a clean, linear history without merge commits. Merge commits add noise and make targeted rollbacks harder to reason about.

### Post-integration validation
After rebasing or merging any set of parallel stream branches into an integration branch, run the project's full validation suite (tests, lint, type-check) before declaring the work complete. Do not move on to the next phase or open an MR until all checks pass. Catching failures per-stream is substantially cheaper than discovering them after all streams are merged.

## Maintainer references

- [Branch naming](https://docs.gitlab.com/user/project/repository/branches/#name-your-branch)
- [Commit message guidelines](https://docs.gitlab.com/development/contributing/merge_request_workflow/#commit-messages-guidelines)
- [Documentation branch naming and pipelines](https://docs.gitlab.com/development/documentation/workflow/#pipelines-and-branch-naming)
