---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Diagnostics tools
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

The GitLab Support team uses these diagnostics tools during troubleshooting. They are listed here for transparency, and
for users with GitLab troubleshooting experience.

If you have an issue with GitLab, you might want to check your [support options](https://about.gitlab.com/support/)
before attempting to use these tools.

## SOS scripts

{{< history >}}

- Bundling of `gitlabsos` with the Linux package and Docker image [introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/8565) in GitLab 18.3.

{{< /history >}}

- [`gitlabsos`](https://gitlab.com/gitlab-com/support/toolbox/gitlabsos/) gathers information and recent logs from a
  Linux package or Docker-based GitLab instance and its operating system.

  ```shell
  sudo gitlabsos
  ```

- [`kubesos`](https://gitlab.com/gitlab-com/support/toolbox/kubesos/) gathers Kubernetes cluster configuration and recent
  logs from a GitLab Helm chart deployment.
- [`gitlab:db:sos`](../raketasks/maintenance.md#collect-information-and-statistics-about-the-database) gathers detailed
  diagnostic data about your database.

## `strace-parser`

[`strace-parser`](https://gitlab.com/gitlab-com/support/toolbox/strace-parser) analyzes and summarizes raw `strace` data.
The [`strace` zine](https://wizardzines.com/zines/strace/) is recommended for context.

## `gitlabrb_sanitizer`

[`gitlabrb_sanitizer`](https://gitlab.com/gitlab-com/support/toolbox/gitlabrb_sanitizer/) outputs a copy of
`/etc/gitlab/gitlab.rb` content with sensitive values redacted.

`gitlabsos` automatically uses `gitlabrb_sanitizer` to sanitize the configuration.

## `fast-stats`

{{< history >}}

- Bundling of `fast-stats` with the Linux package and Docker image [introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/8618) in GitLab 18.3.

{{< /history >}}

To help debug performance and configuration problems,
[`fast-stats`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats#fast-stats) summarizes errors and
resource-intensive usage statistics quickly.

Use `fast-stats` to parse and compare large volumes of logs, or to start troubleshooting unknown problems.

```shell
/opt/gitlab/embedded/bin/fast-stats
```

## `greenhat`

[`greenhat`](https://gitlab.com/gitlab-com/support/toolbox/greenhat/) provides an interactive shell to analyze, filter,
and summarize [SOS logs](#sos-scripts).

## GitLab Detective

[GitLab Detective](https://gitlab.com/gitlab-com/support/toolbox/gitlab-detective) runs automated checks on a GitLab
instance to identify and resolve common issues.
