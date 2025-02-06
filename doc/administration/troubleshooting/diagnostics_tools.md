---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Diagnostics tools
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

These are some of the diagnostics tools the GitLab Support team uses during troubleshooting.
They are listed here for transparency, and for users with experience
with troubleshooting GitLab. If you are currently having an issue with GitLab, you
may want to check your [support options](https://about.gitlab.com/support/) first,
before attempting to use these tools.

## gitlabsos

The [gitlabsos](https://gitlab.com/gitlab-com/support/toolbox/gitlabsos/) utility
provides a unified method of gathering information and logs from GitLab and the system it's
running on.

## strace-parser

[strace-parser](https://gitlab.com/wchandler/strace-parser) is a small tool to analyze
and summarize raw `strace` data.

## `kubesos`

The [`kubesos`](https://gitlab.com/gitlab-com/support/toolbox/kubesos/) utility retrieves GitLab cluster configuration and logs from GitLab Helm chart deployments.
