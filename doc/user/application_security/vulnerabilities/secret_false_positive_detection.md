---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Secret false positive detection
description: Automatic detection and filtering of false positives in secret detection findings.
---

{{< details >}}

- Tier: Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- Introduced in [epic 17885](https://gitlab.com/groups/gitlab-org/-/work_items/20152) in GitLab 18.10 as a [beta](../../../policy/development_stages_support.md#beta) feature with a [feature flag](../../../administration/feature_flags/_index.md) named `duo_secret_detection_false_positive`. [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227074).

{{< /history >}}

Secret false positive detection is an opt-in feature. When you enable it, GitLab Duo analyzes each detected secret to determine the likelihood that it's a false positive. Detection is available for all secret types detected by [GitLab secret detection](../secret_detection/_index.md).

> [!important]
> When this feature is enabled, information about the vulnerability, including the code context surrounding the detected secret, is sent to large language models (LLMs) for analysis. The behavior described in the [secret detection and redaction](../../gitlab_duo/data_usage.md#secret-detection-and-redaction) documentation does not apply to this feature. Review your organization's data policies before enabling this feature.

The GitLab Duo assessment includes information about each false positive finding:

- Confidence score: A numerical score that indicates the likelihood that the finding is a false positive.
- Explanation: Reasons why the finding may or may not be a true positive, based on code context and secret characteristics.
- Visual indicator: A badge in the vulnerability report that shows the false positive assessment.

Once enabled, false positive detection runs automatically after each security scan without manual intervention.

Results are based on AI analysis and should be reviewed by security professionals. The feature requires GitLab Duo with an active subscription.

## Automatic detection

False positive detection runs automatically in the following scenarios:

- A secret detection scan completes successfully on the default branch.
- The scan detects secrets.
- GitLab Duo features are enabled for the project.

The analysis runs in the background and results appear in the vulnerability report once processing is complete.

## Manual trigger

You can manually run false positive detection for existing vulnerabilities:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Secure** > **Vulnerability report**.
1. Select the vulnerability you want to analyze.
1. In the upper-right corner, select **Check for false positive** to trigger false positive detection.

The GitLab Duo analysis runs and displays the results on the vulnerability details page.

## Configuration

To use false positive detection, you must have the following requirements:

- A GitLab Duo add-on subscription (GitLab Duo Core, Pro, or Enterprise).
- [GitLab Duo enabled](../../gitlab_duo/turn_on_off.md) in your project or group.
- [A default GitLab Duo namespace set](../../profile/preferences.md#set-a-default-gitlab-duo-namespace) in your user preferences.
- GitLab 18.10 or later.

### Enable false positive detection

False positive detection is turned off by default and must be explicitly enabled. When enabled, information about the vulnerability, including surrounding code context, is sent to LLMs for analysis. To use this feature, you must enable the foundational flow for the group and turn on the feature for the project.

#### Allow foundational flow for a group

You can allow all projects in a group to use the foundational flow. Individual projects must still enable the feature in their project settings.
To allow false positive detection for all projects in a group:

1. In the left sidebar, select **Search or go to** and find your group.
1. Select **Settings** > **GitLab Duo**.
1. Under **Allow foundational flows**, select the **Secret Detection False Positive Detection** checkbox.
1. Select **Save changes**.

#### Turn on for a project

To turn on false positive detection for a specific project:

1. In the left sidebar, select **Search or go to** and find your project.
1. Select **Settings** > **General**.
1. Expand **GitLab Duo**.
1. Turn on the **Turn on secret detection false positive detection** toggle.
1. Select **Save changes**.

When you allow false positive detection for the group and turn it on for the project, the feature works automatically with your existing secret detection scanners.

## Confidence scores

The confidence score estimates how likely the GitLab Duo assessment is to be correct:

- Likely false positive (80-100%): GitLab Duo is highly confident that the finding is a false positive.
- Possible false positive (60-79%): GitLab Duo has reasonable confidence that the finding may be a false positive but recommends manual review.
- Likely not a false positive (&lt;60%): GitLab Duo is not confident that the finding is a false positive. Manual review is strongly recommended before you dismiss the vulnerability.

## Dismissing false positives

When the GitLab Duo analysis identifies a vulnerability as a false positive, you have the following options:

- Dismiss the vulnerability
- Remove the false positive flag

### Dismiss the vulnerability

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Secure** > **Vulnerability report**.
1. Select the vulnerability you want to dismiss.
1. Select **Change status**.
1. From the **Status** dropdown list, select **Dismissed**.
1. From the **Set dismissal reason** dropdown list, select **False positive**.
1. In the **Add a comment** input, provide context about why you're dismissing it as a false positive.
1. Select **Change status**.

The vulnerability is marked as dismissed and does not appear in future scans unless it is reintroduced.

### Remove the false positive flag

If you want to remove the false positive assessment and keep the vulnerability:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Secure** > **Vulnerability report**.
1. Locate the vulnerability with the false positive flag.
1. Hover over the false positive badge on the vulnerability.
1. Select **Remove False Positive Flag**.

The false positive flag is removed and the FP confidence score reverts to 0. The vulnerability remains in the report and can be re-evaluated in future scans.

## Providing feedback

False positive detection is a beta feature and we welcome your feedback. If you encounter issues or have suggestions for improvement, please provide feedback in [issue 592861](https://gitlab.com/gitlab-org/gitlab/-/work_items/592861).

## Related topics

- [Vulnerability details](_index.md)
- [Vulnerability report](../vulnerability_report/_index.md)
- [Secret detection](../secret_detection/_index.md)
- [GitLab Duo](../../gitlab_duo/_index.md)
