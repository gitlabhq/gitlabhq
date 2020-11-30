---
type: reference, dev
stage: none
group: Development
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
description: "GitLab development - how to document features deployed behind feature flags"
---

# Document features deployed behind feature flags

GitLab uses [Feature Flags](../feature_flags/index.md) to strategically roll
out the deployment of its own features. The way we document a feature behind a
feature flag depends on its state (enabled or disabled). When the state
changes, the developer who made the change **must update the documentation**
accordingly.

## Criteria

According to the process of [deploying GitLab features behind feature flags](../feature_flags/process.md):

> - _By default, feature flags should be off._
> - _Feature flags should remain in the codebase for a short period as possible to reduce the need for feature flag accounting._
> - _In order to build a final release and present the feature for self-managed users, the feature flag should be at least defaulted to on._

See how to document them below, according to the state of the flag:

- [Features disabled by default](#features-disabled-by-default).
- [Features that became enabled by default](#features-that-became-enabled-by-default).
- [Features directly enabled by default](#features-directly-enabled-by-default).
- [Features that can be enabled or disabled for a single project](#features-enabled-by-project).
- [Features with the feature flag removed](#features-with-flag-removed).

The [`**(CORE ONLY)**`](styleguide/index.md#product-tier-badges) badge or equivalent for
the feature's tier should be added to the line and heading that refers to
enabling/disabling feature flags as Admin access is required to do so,
therefore, it indicates that it cannot be done by regular users of GitLab.com.

### Features disabled by default

For features disabled by default, if they cannot be used yet due to lack of
completeness, or if they're still under internal evaluation (for example, for
performance implications) do **not document them**: add (or merge) the docs
only when the feature is safe and ready to use and test by end-users.

For feature flags disabled by default, if they can be used by end users:

- Say that it's disabled by default.
- Say whether it's enabled on GitLab.com.
- If the feature can be enabled/disabled for a single project, add the
  [by-project information](#features-enabled-by-project). Otherwise,
  do not say anything about it.
- Say whether it's recommended for production use.
- Document how to enable and disable it.
- Add a warning to the user saying that the feature might be disabled.

For example, for a feature disabled by default, disabled on GitLab.com, cannot
be enabled for a single project, and is not ready for production use:

````markdown
# Feature Name

> - [Introduced](link-to-issue) in GitLab 12.0.
> - It's [deployed behind a feature flag](<replace with path to>/user/feature_flags.md), disabled by default.
> - It's disabled on GitLab.com.
> - It's not recommended for production use.
> - To use it in GitLab self-managed instances, ask a GitLab administrator to [enable it](#anchor-to-section). **(CORE ONLY)**

CAUTION: **Warning:**
This feature might not be available to you. Check the **version history** note above for details.

(...Regular content goes here...)

<!-- Add this at the end of the file -->

### Enable or disable <Feature Name> **(CORE ONLY)**

<Feature Name> is under development and not ready for production use. It is
deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](<replace with path to>/administration/feature_flags.md)
can enable it.

To enable it:

```ruby
Feature.enable(:<feature flag>)
```

To disable it:

```ruby
Feature.disable(:<feature flag>)
```
````

Adjust the blurb according to the state of the feature you're documenting.
Replace `<Feature name>`, `**(CORE ONLY)**`, `<feature flag>`, and
`<replace with path to>`, and `#anchor-to-section` accordingly.

### Features that became enabled by default

For features that were released disabled by default but became enabled by
default:

- Say that it became enabled by default.
- Say whether it's enabled on GitLab.com.
- If the feature can be enabled/disabled for a single project, add the
  [by-project information](#features-enabled-by-project). Otherwise,
  do not say anything about it.
- Say whether it's recommended for production use.
- Document how to disable and enable it.
- Add a warning to the user saying that the feature might be disabled.

For example, for a feature initially deployed disabled by default, that became
enabled by default, that is enabled on GitLab.com, and is ready for production
use:

````markdown
# Feature Name

> - [Introduced](link-to-issue) in GitLab 12.0.
> - It was [deployed behind a feature flag](<replace with path to>/user/feature_flags.md), disabled by default.
> - [Became enabled by default](link-to-issue) on GitLab 12.1.
> - It's enabled on GitLab.com.
> - It's recommended for production use.
> - For GitLab self-managed instances, GitLab administrators can opt to [disable it](#anchor-to-section). **(CORE ONLY)**

CAUTION: **Warning:**
This feature might not be available to you. Check the **version history** note above for details.

(...Regular content goes here...)

<!-- Add this at the end of the file -->

### Enable or disable <Feature Name> **(CORE ONLY)**

<Feature Name> is under development but ready for production use.
It is deployed behind a feature flag that is **enabled by default**.
[GitLab administrators with access to the GitLab Rails console](<replace with path to>/administration/feature_flags.md)
can opt to disable it.

To enable it:

```ruby
Feature.enable(:<feature flag>)
```

To disable it:

```ruby
Feature.disable(:<feature flag>)
```
````

Adjust the blurb according to the state of the feature you're documenting.
Replace `<Feature name>`, `**(CORE ONLY)**`, `<feature flag>`,
`<replace with path to>`, and `#anchor-to-section` accordingly.

### Features directly enabled by default

For features enabled by default:

- Say it's enabled by default.
- Say whether it's enabled on GitLab.com.
- If the feature can be enabled/disabled for a single project, add the
  [by-project information](#features-enabled-by-project). Otherwise,
  do not say anything about it.
- Say whether it's recommended for production use.
- Document how to disable and enable it.
- Add a warning to the user saying that the feature might be disabled.

For example, for a feature enabled by default, enabled on GitLab.com, that
cannot be enabled for a single project, and is ready for production use:

````markdown
# Feature Name

> - [Introduced](link-to-issue) in GitLab 12.0.
> - It's [deployed behind a feature flag](<replace with path to>/user/feature_flags.md), enabled by default.
> - It's enabled on GitLab.com.
> - It's recommended for production use.
> - For GitLab self-managed instances, GitLab administrators can opt to [disable it](#anchor-to-section). **(CORE ONLY)**

CAUTION: **Warning:**
This feature might not be available to you. Check the **version history** note above for details.

(...Regular content goes here...)

<!-- Add this at the end of the file -->

### Enable or disable <Feature Name> **(CORE ONLY)**

<Feature Name> is under development but ready for production use.
It is deployed behind a feature flag that is **enabled by default**.
[GitLab administrators with access to the GitLab Rails console](<replace with path to>/administration/feature_flags.md)
can opt to disable it.

To enable it:

```ruby
Feature.enable(:<feature flag>)
```

To disable it:

```ruby
Feature.disable(:<feature flag>)
```
````

Adjust the blurb according to the state of the feature you're documenting.
Replace `<Feature name>`, `**(CORE ONLY)**`, `<feature flag>`,
`<replace with path to>`, and `#anchor-to-section` accordingly.

### Features enabled by project

If the feature can be enabled/disabled for a single project, include in the
version history note:

```markdown
> - It can be enabled or disabled for a single project.
```

Then add the by-project code to the code blocks:

Enable code:

```ruby
# For the instance
Feature.enable(:<feature flag>)
# For a single project
Feature.enable(:<feature flag>, Project.find(<project id>))
```

Disable code:

```ruby
# For the instance
Feature.disable(:<feature flag>)
# For a single project
Feature.disable(:<feature flag>, Project.find(<project id>))
```

For example, for a feature enabled by default, enabled on GitLab.com, that can
be enabled by project, and is ready for production use:

````markdown
# Feature Name

> - [Introduced](link-to-issue) in GitLab 12.0.
> - It's [deployed behind a feature flag](<replace with path to>/user/feature_flags.md), enabled by default.
> - It's enabled on GitLab.com.
> - It can be enabled or disabled for a single project.
> - It's recommended for production use.
> - For GitLab self-managed instances, GitLab administrators can opt to [disable it](#anchor-to-section). **(CORE ONLY)**

CAUTION: **Warning:**
This feature might not be available to you. Check the **version history** note above for details.

(...Regular content goes here...)

<!-- Add this at the end of the file -->

### Enable or disable <Feature Name> **(CORE ONLY)**

<Feature Name> is under development but ready for production use.
It is deployed behind a feature flag that is **enabled by default**.
[GitLab administrators with access to the GitLab Rails console](<replace with path to>/administration/feature_flags.md)
can opt to disable it.

To enabled it:

```ruby
# For the instance
Feature.enable(:<feature flag>)
# For a single project
Feature.enable(:<feature flag>, Project.find(<project id>))
```

To disable it:

```ruby
# For the instance
Feature.disable(:<feature flag>)
# For a single project
Feature.disable(:<feature flag>, Project.find(<project id>))
```
````

Adjust the blurb according to the state of the feature you're documenting.
Replace `<Feature name>`, `**(CORE ONLY)**`, `<feature flag>`,
`<replace with path to>`, and `#anchor-to-section` accordingly.

### Features with flag removed

Once the feature is ready and the flag has been removed, clean up the
documentation. Remove the feature flag mention keeping only a note that
mentions the flag in the version history notes:

````markdown
# Feature Name

> - [Introduced](link-to-issue) in GitLab 12.0.
> - [Feature flag removed](link-to-issue) in GitLab 12.2.

(...Regular content...)

````
