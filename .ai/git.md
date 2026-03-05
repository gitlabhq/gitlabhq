# Git workflow rules

Before creating any branch or commit, validate against all rules in this file.

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

## Maintainer references

- [Branch naming](https://docs.gitlab.com/user/project/repository/branches/#name-your-branch)
- [Commit message guidelines](https://docs.gitlab.com/development/contributing/merge_request_workflow/#commit-messages-guidelines)
- [Documentation branch naming and pipelines](https://docs.gitlab.com/development/documentation/workflow/#pipelines-and-branch-naming)
