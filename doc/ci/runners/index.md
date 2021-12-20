---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Runner SaaS **(FREE SAAS)**

If you are using self-managed GitLab or you use GitLab.com but want to use your own runners, you can
[install and configure your own runners](https://docs.gitlab.com/runner/install/).

If you are using GitLab SaaS (GitLab.com), your CI jobs automatically run on runners provided by GitLab.
No configuration is required. Your jobs can run on:

- [Linux runners](build_cloud/linux_build_cloud.md).
- [Windows runners](build_cloud/windows_build_cloud.md) (beta).
- [macOS runners](build_cloud/macos_build_cloud.md) (beta).

The number of minutes you can use on these runners depends on the
[maximum number of CI/CD minutes](../pipelines/cicd_minutes.md)
in your [subscription plan](https://about.gitlab.com/pricing/).
