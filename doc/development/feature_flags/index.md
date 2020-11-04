---
stage: none
group: Development
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
---

# Feature flags in development of GitLab

Feature flags can be used to gradually deploy changes, regardless of whether
they are new features or performance improvements. By using feature flags,
you can determine the impact of GitLab-directed changes, while still being able
to disable those changes without having to revert an entire release.

Before using feature flags for GitLab's development, review the following development guides:

NOTE: **Note:**
The feature flags used by GitLab to deploy its own features **are not** the same
as the [feature flags offered as part of the product](../../operations/feature_flags.md).

For an overview about starting with feature flags in GitLab's development,
use this [training template](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/.gitlab/issue_templates/feature-flag-training.md).

Development guides:

- [Process for using features flags](process.md): When you should use
  feature flags in the development of GitLab, what's the cost of using them,
  and how to include them in a release.
- [Developing with feature flags](development.md): Learn about the types of
  feature flags, their definition and validation, how to create them, frontend and
  backend details, and other information.
- [Documenting features deployed behind feature flags](../documentation/feature_flags.md):
  How to document features deployed behind feature flags, and how to update the
  documentation for features' flags when their states change.
- [Controlling feature flags](controls.md): Learn the process for deploying
  a new feature, enabling it on GitLab.com, communicating the change,
  logging, and cleaning up.

User guides:

- [How GitLab administrators can enable and disable features behind flags](../../administration/feature_flags.md):
  An explanation for GitLab administrators about how they can
  enable or disable GitLab features behind feature flags.
- [What "features deployed behind flags" means to the GitLab user](../../user/feature_flags.md):
  An explanation for GitLab users regarding how certain features
  might not be available to them until they are enabled.
