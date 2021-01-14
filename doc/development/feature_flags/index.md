---
stage: none
group: Development
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
---

# Feature flags in development of GitLab

**NOTE**:
The documentation below covers feature flags used by GitLab to deploy its own features, which **is not** the same
as the [feature flags offered as part of the product](../../operations/feature_flags.md).

## When to use feature flags

Developers are required to use feature flags for changes that could affect availability of existing GitLab functionality (if it only affects the new feature you're making that is probably acceptable).
Such changes include:

1. New features in high traffic areas (e.g. a new merge request widget, new option in issues/epics, new CI functionality).
1. Complex performance improvements that may require additional testing in production (e.g. rewriting complex queries, changes to frequently used API endpoints).
1. Invasive changes to the user interface (e.g. introducing a new navigation bar, removal of a sidebar, UI element change in issues or MR interface).
1. Introducing dependencies on third-party services (e.g. adding support for importing projects).
1. Changes to features that can cause data corruption or cause data loss (e.g. features processing repository data or user uploaded content).

Situations where you might consider not using a feature flag:

1. Adding a new API endpoint
1. Introducing new features in low traffic areas (e.g. adding a new export functionality in the admin area/group settings/project settings)
1. Non-invasive frontend changes (e.g. changing the color of a button, or moving a UI element in a low traffic area)

In all cases, those working on the changes should ask themselves:

> Why do I need to add a feature flag? If I don't add one, what options do I have to control the impact on application reliability, and user experience?

For perspective on why we limit our use of feature flags please see the following [video](https://www.youtube.com/watch?v=DQaGqyolOd8). 

In case you are uncertain if a feature flag is necessary, simply ask about this in an early merge request, and those reviewing the changes will likely provide you with an answer.

When using a feature flag for UI elements, make sure to _also_ use a feature
flag for the underlying backend code, if there is any. This ensures there is
absolutely no way to use the feature until it is enabled.

## How to use Feature Flags

Feature flags can be used to gradually deploy changes, regardless of whether
they are new features or performance improvements. By using feature flags,
you can determine the impact of GitLab-directed changes, while still being able
to disable those changes without having to revert an entire release.

For an overview about starting with feature flags in GitLab development,
use this [training template](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/.gitlab/issue_templates/feature-flag-training.md).

Before using feature flags for GitLab development, review the following development guides:

1. [Process for using features flags](process.md): When you should use
  feature flags in the development of GitLab, what's the cost of using them,
  and how to include them in a release.
1. [Developing with feature flags](development.md): Learn about the types of
  feature flags, their definition and validation, how to create them, frontend and
  backend details, and other information.
1. [Documenting features deployed behind feature flags](../documentation/feature_flags.md):
  How to document features deployed behind feature flags, and how to update the
  documentation for features' flags when their states change.
1. [Controlling feature flags](controls.md): Learn the process for deploying
  a new feature, enabling it on GitLab.com, communicating the change,
  logging, and cleaning up.

User guides:

1. [How GitLab administrators can enable and disable features behind flags](../../administration/feature_flags.md):
  An explanation for GitLab administrators about how they can
  enable or disable GitLab features behind feature flags.
1. [What "features deployed behind flags" means to the GitLab user](../../user/feature_flags.md):
  An explanation for GitLab users regarding how certain features
  might not be available to them until they are enabled.
