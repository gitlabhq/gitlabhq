---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# GitLab SaaS runners

If you are using self-managed GitLab or you want to use your own runners on GitLab.com, you can
[install and configure your own runners](https://docs.gitlab.com/runner/install/).

If you are using GitLab SaaS (GitLab.com), your CI jobs automatically run on shared runners. No configuration is required.
Your jobs can run on [Linux](build_cloud/linux_build_cloud.md) or [Windows](build_cloud/windows_build_cloud.md).

The number of minutes you can use on these shared runners depends on your
[quota](../../user/admin_area/settings/continuous_integration.md#shared-runners-pipeline-minutes-quota),
which depends on your [subscription plan](../../subscriptions/gitlab_com/index.md#ci-pipeline-minutes).
