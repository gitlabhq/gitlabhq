---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Secret detection exclusions
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14878) as an [experiment](../../../policy/development_stages_support.md) in GitLab 17.5 [with a flag](../../feature_flags.md) named `secret_detection_project_level_exclusions`. Enabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/499059) in GitLab 17.7. Feature flag `secret_detection_project_level_exclusions` removed.

Secret detection may detect something that's not actually a secret. For example, if you use
a fake value as a placeholder in your code, it might be detected and possibly blocked.

To avoid false positives you can exclude from secret detection:

- A path.
- A raw value.
- A rule from the [default ruleset](https://gitlab.com/gitlab-org/gitlab/-/blob/master/gems/gitlab-secret_detection/lib/gitleaks.toml)

You can define multiple exclusions for a project.

## Restrictions

The following restrictions apply:

- Exclusions can only be defined for each project.
- Exclusions apply only to [secret push protection](secret_push_protection/_index.md).
- The maximum number of path-based exclusions per project is 10.
- The maximum depth for path-based exclusions is 20.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Secret Detection Exclusions - Demonstration](https://www.youtube.com/watch?v=vh_Uh4_4aoc).
<!-- Video published on 2024-10-12 -->

## Add an exclusion

Define an exclusion to avoid false positives from secret detection.

Path exclusions support glob patterns which are supported and interpreted with the Ruby method
[`File.fnmatch`](https://docs.ruby-lang.org/en/master/File.html#method-c-fnmatch)
with the [flags](https://docs.ruby-lang.org/en/master/File/Constants.html#module-File::Constants-label-Filename+Globbing+Constants+-28File-3A-3AFNM_-2A-29)
`File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB`.

Prerequisites:

- You must have the **Maintainer** role for the project.

To define an exclusion:

1. In the left sidebar, select **Search or go to** and go to your project or group.
1. Select **Secure > Security configuration**.
1. Scroll down to **Secret push protection**.
1. Turn on the **Secret push protection** toggle.
1. Select **Configure Secret Detection** (**{settings}**).
1. Select **Add exclusion** to open the exclusion form.
1. Enter the details of the exclusion, then select **Add exclusion**.
