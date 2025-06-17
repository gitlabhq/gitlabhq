---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Diagnostics tools
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

These are some of the diagnostics tools the GitLab Support team uses during troubleshooting.
They are listed here for transparency, and for users with experience
with troubleshooting GitLab. If you are currently having an issue with GitLab, you
may want to check your [support options](https://about.gitlab.com/support/) first,
before attempting to use these tools.

## SOS scripts

- [`gitlabsos`](https://gitlab.com/gitlab-com/support/toolbox/gitlabsos/)
  gathers information and recent logs from a Linux package or Docker-based GitLab instance
  and its operating system.
- [`kubesos`](https://gitlab.com/gitlab-com/support/toolbox/kubesos/)
  gathers k8s cluster configuration and recent logs from a GitLab Helm chart deployment.
- [`gitlab:db:sos`](../raketasks/maintenance.md#collect-information-and-statistics-about-the-database)
  gathers detailed diagnostic data about your database.

## strace-parser

[`strace-parser`](https://gitlab.com/gitlab-com/support/toolbox/strace-parser)
analyzes and summarize raw `strace` data.
The [`strace` zine](https://wizardzines.com/zines/strace/) is recommended for context.

## `gitlabrb_sanitizer`

[1](https://gitlab.com/gitlab-com/support/toolbox/gitlabrb_sanitizer/) outputs a copy of `/etc/gitlab/gitlab.rb` content with sensitive values redacted.

## `fast-stats`

[`fast-stats`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats#fast-stats)
summarizes errors and resource-intensive usage statistics quickly,
to help debug performance and configuration problems.
`fast-stats` is particularly useful to parse and compare large volumes of logs,
or to start troubleshooting unknown problems.

## `greenhat`

[`greenhat`](https://gitlab.com/gitlab-com/support/toolbox/greenhat/)
provides an interactive shell to analyze, filter, and summarize [SOS logs](#sos-scripts).

## GitLab Detective

[GitLab Detective](https://gitlab.com/gitlab-com/support/toolbox/gitlab-detective)
runs automated checks on a GitLab installation to identify and resolve common issues.
