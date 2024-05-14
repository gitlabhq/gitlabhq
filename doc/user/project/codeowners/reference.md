---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Code Owners syntax and error handling

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

This page describes the syntax and error handling used in Code Owners files,
and provides an example file.

## Code Owners syntax

### Comments

Lines beginning with `#` are ignored:

```plaintext
# This is a comment
```

### Sections

Sections are groups of entries. A section begins with a section heading in square brackets, followed by the entries.

```plaintext
[Section name]
/path/of/protected/file.rb @username
/path/of/protected/dir/ @group
```

#### Section headings

Section headings must always have a name. They can also be made optional, or
require a number of approvals. A list of default owners can be added to the section heading line.

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

Sections names are defined between square brackets. Section names are not case-sensitive.
[Sections with duplicate names](index.md#sections-with-duplicate-names) are combined.

```plaintext
[Section name]
```

#### Required sections

Required sections do not include `^` before the [section name](#section-names).

```plaintext
[Required section]
```

#### Optional sections

Optional sections include a `^` before the [section name](#section-names).

```plaintext
^[Optional section]
```

#### Sections requiring multiple approvals

Sections requiring multiple approvals include the number of approvals in square brackets after the [section name](#section-names).

```plaintext
[Section requiring 5 approvals][5]
```

NOTE:
Optional sections ignore the number of approvals required.

#### Sections with default owners

You can define a default owner for the entries in a section by appending the owners to the [section heading](#section-headings).

```plaintext
# Section with @username as default owner
[Section name] @username

# Section with @group and @subgroup as default owners and requiring 2 approvals
[Section name][2] @group @subgroup
```

### Code Owner entries

Each Code Owner entry includes a path followed by one or more owners.

```plaintext
README.md @username1
```

NOTE:
If an entry is duplicated in a section, [the last entry is used from each section.](index.md#define-more-specific-owners-for-more-specifically-defined-files-or-directories)

### Relative paths

If a path does not start with a `/`, the path is treated as if it starts with
a [globstar](#globstar-paths). `README.md` is treated the same way as `/**/README.md`:

```plaintext
# This will match /README.md, /internal/README.md, /app/lib/README.md
README.md @username

# This will match /internal/README.md, /docs/internal/README.md, /docs/api/internal/README.md
internal/README.md
```

### Absolute paths

If a path starts with a `/` it matches the root of the repository.

```plaintext
# Matches only the file named `README.md` in the root of the repository.
/README.md

# Matches only the file named `README.md` inside the `/docs` directory.
/docs/README.md
```

### Directory paths

If a path ends with `/`, the path matches any file in the directory.

```plaintext
# This is the same as `/docs/**/*`
/docs/
```

### Wildcard paths

Wildcards can be used to match one of more characters of a path.

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

Globstars (`**`) can be used to match zero or more directories and subdirectories.

```plaintext
# This will match /docs/index.md, /docs/api/index.md, /docs/api/graphql/index.md
/docs/**/index.md
```

### Entry owners

Entries must be followed by one or more owner. These can be groups, subgroups,
and users. Order of owners is not important.

```plaintext
/path/to/entry.rb @group
/path/to/entry.rb @group/subgroup
/path/to/entry.rb @user
/path/to/entry.rb @group @group/subgroup @user
```

#### Groups as entry owners

Groups and subgroups can be owners of an entry.
Each entry can be owned by [one or more owners](#entry-owners).
For more details see the [Add a group as a Code Owner](index.md#add-a-group-as-a-code-owner).

```plaintext
/path/to/entry.rb @group
/path/to/entry.rb @group/subgroup
/path/to/entry.rb @group @group/subgroup
```

### Users as entry owners

Users can be owners of an entry. Each entry can be owned by
[one or more owners](#entry-owners).

```plaintext
/path/to/entry.rb @username1
/path/to/entry.rb @username1 @username2
```

## Error handling in Code Owners

> - Error validation [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/216066) in GitLab 16.3.

### Entries with spaces

Paths containing whitespace must be escaped with backslashes: `path\ with\ spaces/*.md`.
Without the backslashes, the path after the first whitespace is parsed as an owner.
GitLab the parses `folder with spaces/*.md @group` into
`path: "folder", owners: " with spaces/*.md @group"`.

### Unparsable sections

If a section heading cannot be parsed, the section is:

1. Parsed as an entry.
1. Added to the previous section.
1. If no previous section exists, the section is added to the default section.

For example, this file is missing a square closing bracket:

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

This file contains an unescaped space between the words `Section` and `name`.
GitLab recognizes the intended heading as an entry:

```plaintext
[Docs]
docs/**/* @group

[Section name]{2} @group
docs/ @docs_group
```

The `[Docs]` section then includes 3 rules:

- `docs/**/*` owned by `@group`
- `[Section` owned by `name]{2} @group`
- `docs/` owned by `@docs_group`

### Malformed owners

Each entry must contain 1 or more owners to be valid, malformed owners are ignored.
For example `/path/* @group user_without_at_symbol @user_with_at_symbol`
is owned by `@group` and `@user_with_at_symbol`.

### Inaccessible or incorrect owners

Inaccessible or incorrect owners are ignored. For example, if `@group`, `@username`,
and `example@gitlab.com` are accessible on the project and we create an entry:

```plaintext
* @group @grou @username @i_left @i_dont_exist example@gitlab.com invalid@gitlab.com
```

GitLab ignores `@grou`, `@i_left`, `@i_dont_exist`, and `invalid@gitlab.com`.

For more information on who is accessible, see [Add a group as a Code Owner](index.md#add-a-group-as-a-code-owner).

### Zero owners

If an entry includes no owners, or zero [accessible owners](#inaccessible-or-incorrect-owners)
exist, the entry is invalid. Because this rule can never be satisfied, GitLab
auto-approves it in merge requests.

NOTE:
When a protected branch has `Require code owner approval` enabled, rules with
zero owners are still honored.

### Less than 1 required approval

When [defining the number of approvals](index.md#require-multiple-approvals-from-code-owners) for a section,
the minimum number of approvals is `1`. Setting the number of approvals to
`0` results in GitLab requiring one approval.

## Example `CODEOWNERS` file

```plaintext
# This is an example of a CODEOWNERS file.
# Lines that start with `#` are ignored.

# app/ @commented-rule

# Specify a default Code Owner by using a wildcard:
* @default-codeowner

# Specify multiple Code Owners by using a tab or space:
* @multiple @code @owners

# Rules defined later in the file take precedence over the rules
# defined before.
# For example, for all files with a filename ending in `.rb`:
*.rb @ruby-owner

# Files with a `#` can still be accessed by escaping the pound sign:
\#file_with_pound.rb @owner-file-with-pound

# Specify multiple Code Owners separated by spaces or tabs.
# In the following case the CODEOWNERS file from the root of the repo
# has 3 Code Owners (@multiple @code @owners):
CODEOWNERS @multiple @code @owners

# You can use both usernames or email addresses to match
# users. Everything else is ignored. For example, this code
# specifies the `@legal` and a user with email `janedoe@gitlab.com` as the
# owner for the LICENSE file:
LICENSE @legal this_does_not_match janedoe@gitlab.com

# Use group names to match groups, and nested groups to specify
# them as owners for a file:
README @group @group/with-nested/subgroup

# End a path in a `/` to specify the Code Owners for every file
# nested in that directory, on any level:
/docs/ @all-docs

# End a path in `/*` to specify Code Owners for every file in
# a directory, but not nested deeper. This code matches
# `docs/index.md` but not `docs/projects/index.md`:
/docs/* @root-docs

# Include `/**` to specify Code Owners for all subdirectories
# in a directory. This rule matches `docs/projects/index.md` or
# `docs/development/index.md`
/docs/**/*.md @root-docs

# This code makes matches a `lib` directory nested anywhere in the repository:
lib/ @lib-owner

# This code match only a `config` directory in the root of the repository:
/config/ @config-owner

# If the path contains spaces, escape them like this:
path\ with\ spaces/ @space-owner

# Code Owners section:
[Documentation]
ee/docs    @docs
docs       @docs

# Use of default owners for a section. In this case, all files (*) are owned by
the dev team except the README.md and data-models which are owned by other teams.
[Development] @dev-team
*
README.md @docs-team
data-models/ @data-science-team

# This section is combined with the previously defined [Documentation] section:
[DOCUMENTATION]
README.md  @docs
```
