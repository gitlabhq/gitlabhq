---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SAST False Positive Detection
---

{{< details >}}

- Tier: Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/18977) in GitLab 18.7 as a [beta](../../../../policy/development_stages_support.md#beta) feature [with feature flags](../../../../administration/feature_flags/_index.md) named `enable_vulnerability_fp_detection` and `ai_experiment_sast_fp_detection`. Enabled by default.

{{< /history >}}

SAST false positive detection automatically analyzes critical and high severity SAST vulnerabilities to identify potential false positives. This reduces noise in your vulnerability report by flagging vulnerabilities that are likely not actual security risks.

When a SAST security scan runs, GitLab Duo automatically analyzes each vulnerability to determine the likelihood that it's a false positive. Detection is available for vulnerabilities from [GitLab-supported SAST analyzers](../../../application_security/sast/analyzers.md).

The GitLab Duo assessment includes:

- **Confidence score**: A numerical score indicating the likelihood that the finding is a false positive.
- **Explanation**: Contextual reasoning about why the finding may or may not be a true positive.
- **Visual indicator**: A badge in the vulnerability report showing the assessment.

Results are based on AI analysis and should be reviewed by security professionals. This feature requires GitLab Duo with an active subscription.

## Running SAST false positive detection

The flow runs automatically when:

- A SAST security scan completes successfully.
- The scan detects Critical or High severity vulnerabilities.
- GitLab Duo features are enabled for the project or group.

You can also manually trigger analysis for existing vulnerabilities:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure** > **Vulnerability report**.
1. Select the vulnerability you want to analyze.
1. In the upper-right corner, select **Check for false positive**.

## Related links

- [SAST false positive detection](../../../application_security/vulnerabilities/false_positive_detection.md).
- [Vulnerability report](../../../application_security/vulnerability_report/_index.md).
- [SAST](../../../application_security/sast/_index.md).
