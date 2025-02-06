---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Linux package deprecation policy
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

The Linux packages come with number of different libraries and services which offers users plethora of configuration options.

As libraries and services get updated, their configuration options change
and become obsolete. To increase maintainability and preserve a working
setup, various configuration requires removal.

## Configuration deprecation

### Policy

The Linux package retains configuration for at least **one major**
version. We can't guarantee that deprecated configuration
is available in the next major release. See [example](#example) for more details.

### Notice

If the configuration becomes obsolete, we announce the deprecation:

- via release blog post on `https://about.gitlab.com/blog/`. The blog post item
  contains the deprecation notice together with the target removal date.
- via installation/reconfigure output (if applicable).
- via official documentation on `https://docs.gitlab.com/`. The documentation update contains the corrected syntax (if applicable) or a date of configuration removal.

### Procedure

This section lists steps necessary for deprecating and removing configuration.

We can differentiate two different types of configuration:

- Sensitive: Configuration that can cause major service outage (like data integrity,
  installation integrity, or preventing users from reaching the installation)
- Regular: Configuration that can make a feature unavailable but still makes the
  installation usable (like a change in default project/group settings, or
  miscommunication with other components)

We must also differentiate deprecation and removal procedure.

#### Deprecating configuration

Deprecation procedure is similar for both `sensitive` and `regular` configuration. The only difference is in the removal target date.

Common steps:

1. Create an issue at the [`omnibus-gitlab` issue tracker](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues) with
   details on deprecation type and other necessary information. Apply the label `deprecation`.
1. Decide on the removal target for the deprecated configuration
1. Formulate deprecation notice for each item as noted in [Notice section](#notice)

Removal target:

For regular configuration, removal target should always be the date of the **next major** release. If the date is not known, you can reference the next major version.

For sensitive configuration things are a bit more complicated.
We should aim to not remove sensitive configuration in the *next major* release if the next major release is 2 minor releases away (This number is chosen to match our security backport release policy).

See the table below for some examples:

| Configuration type | Deprecation announced | Final minor release | Remove |
| -------- | -------- | -------- | -------- |
| Sensitive | 10.1.0   | 10.9.0   | 11.0.0 |
| Sensitive | 10.7.0   | 10.9.0   | 12.0.0 |
| Regular | 10.1.0 | 10.9.0 | 11.0.0 |
| Regular | 10.8.0 | 10.9.0 | 11.0.0 |

#### Removing configuration

When deprecation is announced and removal target set, the milestone for the issue
should be changed to match the removal target version.

The final comment in the issue **has to have**:

1. Text snippet for the release blog post section
1. Documentation MR ( or snippet ) for introducing the change
1. Draft MR removing the configuration or details on what must be done. See [Adding deprecation messages](https://docs.gitlab.com/omnibus/development/adding-deprecation-messages.html) for more on this

## Example

User configuration available in `/etc/gitlab/gitlab.rb` was introduced in GitLab version 10.0, `gitlab_rails['configuration'] = true`. In GitLab version 10.4.0, a new change was introduced that requires rename of this configuration option. New configuration option is `gitlab_rails['better_configuration'] = true`. Development team translates the old configuration into a new one
and triggers a deprecation procedure.

This means that these two configuration
options are valid through GitLab version 10. In other words,
if you still have `gitlab_rails['configuration'] = true` set in GitLab 10.8.0
the feature continues working the same way as if you had `gitlab_rails['better_configuration'] = true` set.
However, setting the old version of the configuration prints out a deprecation
notice at the end of installation/upgrade/reconfigure run.

In GitLab 11, `gitlab_rails['configuration'] = true` no longer works and you must manually change the configuration in `/etc/gitlab/gitlab.rb` to the new valid configuration.
**Note** If this configuration option is sensitive and can put integrity of the installation or
data in danger,the installation or upgrade is aborted.
