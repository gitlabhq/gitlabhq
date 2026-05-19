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

## Changelog rules

Add `Changelog: <type>` as the last line of the commit message body.

`added`, `fixed`, `changed`, `deprecated`, `removed`, `security`, `performance`, `other`

For EE-only changes, add `EE: true` on a separate line after the changelog entry.

`added`, `fixed`, `changed`, `deprecated`, `removed`, `security`, `performance`, `other`

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

## Maintainer references

- [Branch naming](https://docs.gitlab.com/user/project/repository/branches/#name-your-branch)
- [Commit message guidelines](https://docs.gitlab.com/development/contributing/merge_request_workflow/#commit-messages-guidelines)
- [Documentation branch naming and pipelines](https://docs.gitlab.com/development/documentation/workflow/#pipelines-and-branch-naming)
