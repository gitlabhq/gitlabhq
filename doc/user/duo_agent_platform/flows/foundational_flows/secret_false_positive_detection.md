---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Secret false positive detection
---

{{< details >}}

- Tier: Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- Introduced in [epic 17885](https://gitlab.com/groups/gitlab-org/-/work_items/20152) in GitLab 18.10 as a [beta](../../../../policy/development_stages_support.md#beta) feature with a [feature flag](../../../../administration/feature_flags/_index.md) named `duo_secret_detection_false_positive`. [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227074).

{{< /history >}}

Secret false positive detection automatically analyzes secret detection findings to identify potential false positives. Dismissing secrets that are likely not actual security risks reduces noise in your vulnerability report.

When a secret detection scan runs, GitLab Duo automatically analyzes each finding to determine the likelihood that it's a false positive. Detection is available for all secret types detected by [GitLab secret detection](../../../application_security/secret_detection/_index.md).

The GitLab Duo assessment includes information about each false positive detection result:

- Confidence score: A numerical score indicating the likelihood that the finding is a false positive.
- Explanation: Reasons why the finding may or may not be a true positive.
- Visual indicator: A badge in the vulnerability report that shows the assessment result.

Results are based on AI analysis and should be reviewed by security professionals. This feature requires GitLab Duo with an active subscription.

## Running secret false positive detection

The flow runs automatically in the following scenarios:

- A secret detection scan completes successfully on the default branch.
- The scan detects secrets.
- GitLab Duo features are enabled for the project or group.

You can also manually trigger analysis for existing vulnerabilities:

1. In the top bar, select **Search or go to** and find your project.
1. Select **Secure** > **Vulnerability report**.
1. Select the vulnerability you want to analyze.
1. In the upper-right corner, select **Check for false positive**.

## Related links

- [Secret detection false positive detection](../../../application_security/vulnerabilities/secret_false_positive_detection.md).
- [Vulnerability report](../../../application_security/vulnerability_report/_index.md).
- [Secret detection](../../../application_security/secret_detection/_index.md).
