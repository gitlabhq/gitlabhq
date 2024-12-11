---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Code Owners syntax and error handling

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

The Code Owners configuration is stored in a `CODEOWNERS` file.
This file determines who should review and approve changes.

This page describes the syntax and error handling used in `CODEOWNERS` files and provides examples of how to use them.

## Example `CODEOWNERS` file

```plaintext
# This is an example of a CODEOWNERS file.
# Lines that start with `#` are ignored.

# Specify a default Code Owner by using a wildcard:
* @default-codeowner

# Specify multiple Code Owners by using a tab or space:
* @multiple @code @owners

# Rules defined later in the file take precedence over earlier rules.
# For example, for all files with a filename ending in `.rb`:
*.rb @ruby-owner

# Files with a `#` can still be accessed by escaping the pound sign:
\#file_with_pound.rb @owner-file-with-pound

# You can use both usernames or email addresses to match users:
LICENSE @legal janedoe@gitlab.com

# Use group names to match groups, and nested groups:
README @group @group/with-nested/subgroup

# Specify Code Owners for directories:
/docs/ @all-docs
/docs/* @root-docs
/docs/**/*.md @root-docs

# Match directories nested anywhere in the repository:
lib/ @lib-owner

# Match only a directory in the root of the repository:
/config/ @config-owner

# If the path contains spaces, escape them like this:
path\ with\ spaces/ @space-owner

# Code Owners sections:
[Documentation]
ee/docs    @docs
docs       @docs

[Development] @dev-team
*
README.md @docs-team
data-models/ @data-science-team

# This section is combined with the previously defined [Documentation] section:
[DOCUMENTATION]
README.md  @docs
```

## Code Owner file loading

The `CODEOWNERS` file is loaded from the target branch.
GitLab checks these locations in your repository in this order:

1. Root directory: `./CODEOWNERS`
1. Documentation directory: `./docs/CODEOWNERS`
1. `.gitlab` directory: `./.gitlab/CODEOWNERS`

The first `CODEOWNERS` file found is used, and all others are ignored.

## Pattern matching

GitLab uses `File::fnmatch` with the `File::FNM_DOTMATCH` and `File::FNM_PATHNAME` flags set for pattern matching:

- The repository structure is treated like an isolated file system.
- The patterns follow a subset of shell filename globbing rules, and are not regular expressions.
- The `File::FNM_DOTMATCH` flag allows `*` to match dotfiles like `.gitignore`.
- The `File::FNM_PATHNAME` flag prevents `*` from matching the `/` path separator.
- `**` matches directories recursively. For example, `**/*.rb` matches `config/database.rb`
  and `app/controllers/users/stars_controller.rb`.

### Comments

Lines beginning with `#` are ignored:

```plaintext
# This is a comment
```

### Sections

Sections are groups of entries. A section begins with a section heading in square brackets `[ ]`:

```plaintext
[Section name]
/path/of/protected/file.rb @username
/path/of/protected/dir/ @group
```

#### Section headings

Section headings must have a name. For protected branches only, they can:

- Require approval (default).
- Be optional (prefixed with `^`).
- Require a specific number of approvals. For more information, see [Group inheritance and eligibility](index.md#group-inheritance-and-eligibility) and [Approvals shown as optional](troubleshooting.md#approvals-shown-as-optional).
- Include default owners.

Examples:

```plaintext
# Required section
[Section name]

# Optional section
^[Section name]

# Section requiring 5 approvals
[Section name][5]

# Section with @username as default owner
[Section name] @username

# Section with @group and @subgroup as default owners and requiring 2 approvals
[Section name][2] @group @subgroup
```

#### Section names

Section names are case-insensitive and defined between square brackets.
[Sections with duplicate names](index.md#sections-with-duplicate-names) are combined.

### Code Owner entries

Each entry includes a path followed by one or more owners.

```plaintext
README.md @username1 @username2
```

NOTE:
If an entry is duplicated in a section, [the last entry is used.](index.md#define-more-specific-owners-for-more-specifically-defined-files-or-directories)

## Path matching

Paths can be absolute, relative, wildcard, or globstar, and are matched against the repository root.

### Relative paths

Paths without a leading `/` are treated as [globstar paths](#globstar-paths):

```plaintext
# Matches /README.md, /internal/README.md, /app/lib/README.md
README.md @username

# Matches /internal/README.md, /docs/internal/README.md, /docs/api/internal/README.md
internal/README.md
```

NOTE:
When using globstar paths, be cautious of unintended matches.
For example, `README.md` without a leading `/` matches any `README.md`
file in any directory or subdirectory of the repository.

### Absolute paths

Paths starting with `/` match from the repository root:

```plaintext
# # Matches only README.md in the root.
/README.md

# Matches only README.md inside the /docs directory.
/docs/README.md
```

### Directory paths

Paths ending with `/` match any file in the directory:

```plaintext
# This is the same as `/docs/**/*`
/docs/
```

### Wildcard paths

Use wildcards to match multiple characters:

```plaintext
# Any markdown files in the docs directory
/docs/*.md @username

# /docs/index file of any filetype
# For example: /docs/index.md, /docs/index.html, /docs/index.xml
/docs/index.* @username

# Any file in the docs directory with 'spec' in the name.
# For example: /docs/qa_specs.rb, /docs/spec_helpers.rb, /docs/runtime.spec
/docs/*spec* @username

# README.md files one level deep within the docs directory
# For example: /docs/api/README.md
/docs/*/README.md @username
```

### Globstar paths

Use `**` to match zero or more directories recursively:

```plaintext
# Matches /docs/index.md, /docs/api/index.md, and /docs/api/graphql/index.md.
/docs/**/index.md
```

## Entry owners

Entries must have one or more owners These can be groups, subgroups,
and users.

```plaintext
/path/to/entry.rb @group
/path/to/entry.rb @group/subgroup
/path/to/entry.rb @user
/path/to/entry.rb @group @group/subgroup @user
```

For more information on adding groups as Code Owners, see [Add a group as a Code Owner](index.md#add-a-group-as-a-code-owner).

## Error handling

> - Error validation [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/216066) in GitLab 16.3.

### Entries with spaces

Escape whitespace in paths with backslashes:

```plaintext
path\ with\ spaces/*.md @owner
```

Without escaping, GitLab parses `folder with spaces/*.md @group` as: `path: "folder", owners: " with spaces/*.md @group"`.

### Unparsable sections

If a section heading cannot be parsed, the section is:

1. Parsed as an entry.
1. Added to the previous section.
1. If no previous section exists, the section is added to the default section.

#### After the default section

```plaintext
* @group

[Section name
docs/ @docs_group
```

GitLab recognizes the heading `[Section name` as an entry. The default section includes 3 rules:

- Default section
  - `*` owned by `@group`
  - `[Section` owned by `name`
  - `docs/` owned by `@docs_group`

#### After a named section

```plaintext
[Docs]
docs/**/* @group

[Section name
docs/ @docs_group
```

GitLab recognizes the heading `[Section name` as an entry. The `[Docs]` section includes 3 rules:

- `docs/**/*` owned by `@group`
- `[Section` owned by `name`
- `docs/` owned by `@docs_group`

### Malformed owners

Each entry must contain one or more owners. Malformed owners are invalid and ignored:

```plaintext
/path/* @group user_without_at_symbol @user_with_at_symbol
```

This entry is owned by `@group` and `@user_with_at_symbol`.

### Inaccessible or incorrect owners

GitLab ignores inaccessible or incorrect owners. For example:

```plaintext
* @group @grou @username @i_left @i_dont_exist example@gitlab.com invalid@gitlab.com
```

If only `@group`, `@username`, and `example@gitlab.com` are accessible, GitLab ignores the others.

### Zero owners

If an entry includes no owners, or zero [accessible owners](#inaccessible-or-incorrect-owners)
exist, the entry is invalid. Because this rule can never be satisfied, GitLab
auto-approves it in merge requests.

NOTE:
When a protected branch has `Require code owner approval` enabled, rules with
zero owners are still honored.

### Minimum approvals

When [defining the number of approvals](index.md#require-multiple-approvals-from-code-owners) for a section,
the minimum number of approvals is `1`. Setting the number of approvals to
`0` results in GitLab requiring one approval.

## Related topics

- [Code Owners](index.md)
- [Merge request approvals](../merge_requests/approvals/index.md)
- [Protected branches](../repository/branches/protected.md)
- [Troubleshooting Code Owners](troubleshooting.md)
