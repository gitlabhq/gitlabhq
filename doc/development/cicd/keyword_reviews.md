---
stage: Verify
group: Pipeline Authoring
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: YAML syntax change review guide
---

Use this checklist when reviewing merge requests that add or modify CI/CD YAML keywords,
to ensure complete specification, documentation, and testing.

## Review checklist

### Path-based keywords

When a keyword accepts file or directory paths:

#### Behavior

- [ ] Does it support glob patterns? Document which patterns: `*`, `**`, `?`
- [ ] Does it support relative paths? Absolute paths? Nested paths?
- [ ] What is the base directory for relative paths?
- [ ] Are symbolic links followed?
- [ ] What happens when the path does not exist?

#### Specification and testing

- [ ] Are all path handling behaviors covered by specs?
- [ ] Are edge cases tested? (empty paths, special characters, very long paths)
- [ ] If a behavior is intentionally _not_ supported (for example, no glob support), is that:
  - [ ] Explicitly documented as a limitation?
  - [ ] Covered by a spec that documents the current behavior? (If the limitation is later – intentionally or not – removed, the failing test will alert and prevent a breaking change for pipelines that depend on the current behavior.)

### Variables

#### Behavior

- [ ] Are variables expanded in this context?
- [ ] Is nested variable expansion supported?
- [ ] Is expansion happening during config parsing (Rails/backend)? Or just because variables are passed through to the Runner unexpanded?

#### Specification and testing

- [ ] Is variable expansion behavior, i.e. [type of expansion](../../ci/variables/where_variables_can_be_used.md#expansion-mechanisms) and other relevant details, specified in the [documentation table](../../ci/variables/where_variables_can_be_used.md#variables-usage)?
- [ ] Are both positive (expansion works) and negative (expansion does not work)
  cases explicitly tested?
- [ ] If nested expansion does not work, is there a spec preventing accidental
  future enablement? Accidentally enabling nested expansion could be a breaking
  change for users whose pipelines depend on the current behavior.
- [ ] Does the keyword documentation on the YAML reference page specify what works and what does not?

### Keyword reuse and consistency

When adding an existing keyword name as a subkeyword (for example, adding
`include:` as a subkeyword within another keyword):

#### Behavior

- [ ] Does it support *all* functionality and sub-keywords of the original keyword?
- [ ] If not, are the limitations explicitly documented?
- [ ] What happens when users try to use features from the original keyword that aren't supported in the subkeyword? (See [this comment](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/202903#note_2732603714) around expectations and acceptable failure modes.)
  - [ ] Are there clear error messages when unsupported syntax is used?

#### Specification and testing

- [ ] If this subkeyword doesn't support all features of the original keyword, are the unsupported features documented?
- [ ] Does validation properly reject incompatible syntax with specific errors?
- [ ] Do tests cover scenarios where a user assumes the subkeyword works
  identically to the original?

### Composability

How does the keyword behave in combination with CI composability options:

#### Behavior

- [ ] [YAML anchors](../../ci/yaml/yaml_optimization.md#anchors) – native YAML functionality, usually not a concern
- [ ] The [`!reference` tag](../../ci/yaml/yaml_optimization.md#reference-tags) – a custom extension, a very frequent source of unexpected behavior
  - [ ] Does the `!reference` tag work when used in or under the keyword?
  - [ ] Does the keyword work when used in a section that is pulled in via a `!reference` tag?
- [ ] [Includes](../../ci/yaml/_index.md#include)
  - [ ] Is it okay for the keyword to be used in *all* types of include? (Example: Is there a reason the keyword should not be used in components?)
  - [ ] Has the semantics of the keyword being used in an included file been considered? (Example: What does `include:local:` mean when being used in a file that is included via `include:project:` – which of the two projects is considered the local one?)
- [ ] [`extends`](../../ci/yaml/yaml_optimization.md#use-extends-to-reuse-configuration-sections) – deep-merges hashes but *replaces* arrays, which can surprise keywords that take a list
  - [ ] Does the keyword merge as expected when a job uses `extends`?

#### Specification and testing

- [ ] Is the `!reference` tag behavior documented and tested?
- [ ] Is the `include:` behavior documented and tested?
- [ ] Is the `extends:` merge behavior documented and tested?
- [ ] Does validation properly reject unwanted `!reference` tag and `include:` usage?
- [ ] Do the specs account for intentionally _not_ supported composability?

### Performance and usage limits

Any usage dimension without a limit will eventually (and often unintentionally) be exploited at scale, causing performance problems that are difficult to address without breaking changes. Every keyword must have relevant limits in place before going into the product.

- [ ] Are there limits in place for every relevant dimension?
  - Length of a string/value
  - Amount of entries in a list/array
- [ ] Is the limit documented?
  - [ ] Does the limit documentation explain potential performance impact of raising the limit?

### Documentation and specification completeness

- [ ] Is all documented behavior covered by specs and tests?
- [ ] Is all implemented behavior documented?
- [ ] Are validation errors specific and actionable?
- [ ] Is validation via the [JSON schema](schema.md) consistent with validation in the backend?
- [ ] Is the syntax reference updated with the new or changed keyword?
- [ ] Do examples cover common use cases?
- [ ] Are limitations and gotchas clearly called out?

## Feature flags for CI syntax/processing changes

Changes that impact CI YAML parsing should be behind a feature flag. The flag has
to be default-enabled for a full milestone before being removed. This is to ensure
that Self-Managed and Dedicated users can always revert to the original behavior
in case of unexpected side effects.

## Common pitfalls

### No nested variable expansion in `rules:exists`

[GitLab issue #411344](https://gitlab.com/gitlab-org/gitlab/-/issues/411344):
`VAR1: $VAR2` did not expand in `rules:exists`. This was not clearly documented,
users perceived it as a bug when it might not even initially have been planned
to be supported.

Lesson: Be intentional about scope, and consider that user expectations will
always default to the maximum.

### Include keyword typos silently ignored

[GitLab issue #549736](https://gitlab.com/gitlab-org/gitlab/-/issues/549736):
Using `files` instead of `file` is silently ignored if it is not the only include,
allowing invalid YAML to execute with unexpected results.

Lesson: Consider common keyword combinations and real-world usage in tests. Even
an explicit test for this that only checks a single include would not catch this.

### Cache key files glob patterns broken

[GitLab issue #572701](https://gitlab.com/gitlab-org/gitlab/-/issues/572701):
Wildcard patterns in `cache:key:files` stopped working and fell back to the
`default` key instead, causing incorrect cache reuse.

Lesson: When changing existing keywords, verify that all possible usage patterns
are covered by specs, and close any gaps before making changes.

## Getting help

1. Questions: [`#g_pipeline-authoring`](https://gitlab.slack.com/archives/g_pipeline-authoring) Slack channel
1. Review requests: Mention `@gitlab-org/maintainers/cicd-verify` in your MR
1. Feedback on this guide: Open a merge request to update this page
