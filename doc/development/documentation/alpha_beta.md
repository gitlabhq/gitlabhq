---
info: For assistance with this Style Guide page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects
stage: none
group: unassigned
---

# Documenting Experiment and Beta features

Some features are not generally available and are instead considered
[Experiment or Beta](../../policy/alpha-beta-support.md).

When you document a feature in one of these three statuses:

- Add `(Experiment)` or `(Beta)` in parentheses after the page or topic title.
- Do not include `(Experiment)` or `(Beta)` in the left nav.
- Ensure the version history lists the feature's status.

These features are usually behind a feature flag, which follow [these documentation guidelines](feature_flags.md).

If you add details of how users should enroll, or how to contact the team with issues,
the `FLAG:` note should be above these details.

For example:

```markdown
## Great new feature (Experiment)

> [Introduced](link) in GitLab 15.10. This feature is an [Experiment](<link_to>/policy/alpha-beta-support.md).

FLAG:
On self-managed GitLab, by default this feature is not available.
To make it available, ask an administrator to enable the feature flag named `example_flag`.
On GitLab.com, this feature is not available. This feature is not ready for production use.

Use this great new feature when you need to do this new thing.

This feature is an [Experiment](<link_to>/policy/alpha-beta-support.md). To join
the list of users testing this feature, do this thing. If you find a bug,
[open an issue](link).
```

When the feature is ready for production, remove:

- The text in parentheses.
- Any language about the feature not being ready for production in the body
  description.
- The feature flag information if available.

Ensure the version history is up-to-date by adding a note about the production release.
