---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SAST false positive detection
description: Automatic detection and filtering of false positives in SAST findings.
---

{{< details >}}

- Tier: Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/18977) in GitLab 18.7 as a [beta](../../../policy/development_stages_support.md#beta) [with feature flags](../../../administration/feature_flags/_index.md) named `enable_vulnerability_fp_detection` and `ai_experiment_sast_fp_detection`. Enabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

When a static application security testing (SAST) scan runs, GitLab Duo automatically analyzes each Critical and High severity SAST vulnerabilities to determine the likelihood that it's a false positive. Detection is available for vulnerabilities from [GitLab-supported SAST analyzers](../sast/analyzers.md).

The GitLab Duo assessment includes:

- Confidence score: A numerical score indicating the likelihood that the finding is a false positive.
- Explanation: Contextual reasoning about why the finding may or may not be a true positive, based on code context and vulnerability characteristics.
- Visual indicator: A badge in the vulnerability report showing the false positive assessment.

The detection runs automatically after each security scan with no manual triggering required.

Results are based on AI analysis and should be reviewed by security professionals. The feature requires GitLab Duo with an active subscription.

## Automatic detection

False positive detection runs automatically when:

- A SAST security scan completes successfully on the default branch.
- The scan detects Critical or High severity vulnerabilities.
- GitLab Duo features are enabled for the project.

The analysis happens in the background and results appear in the vulnerability report once processing is complete.

## Manual trigger

You can manually trigger false positive detection for existing vulnerabilities:

1. On the top bar, select **Search or go to** and find your project.
1. Select **Secure** > **Vulnerability report**.
1. Select the vulnerability you want to analyze.
1. In the upper-right corner, select **Check for false positive** to trigger false positive detection.

The GitLab Duo analysis runs and results are displayed on the vulnerability details page.

## Configuration

To use false positive detection, you must have:

- A GitLab Duo add-on subscription (GitLab Duo Core, Pro, or Enterprise).
- [GitLab Duo enabled](../../gitlab_duo/turn_on_off.md) in your project or group.
- [A default GitLab Duo namespace set](../../profile/preferences.md#set-a-default-gitlab-duo-namespace) in your user preferences.
- GitLab 18.7 or later.

### Enable false positive detection

False positive detection is turned off by default. To use this feature, you must enable the foundational flow for the group and turn on the feature for the project.

#### Allow foundational flow for a group

You can allow all projects in a group to use the foundational flow. Individual projects must still enable the feature in their project settings.
To allow false positive detection for all projects in a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings** > **GitLab Duo**.
1. Under **Allow foundational flows**, select the **SAST False Positive Detection** checkbox.
1. Select **Save changes**.

#### Turn on for a project

To turn on false positive detection for a specific project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings** > **General**.
1. Expand **GitLab Duo**.
1. Turn on the **Turn on SAST false positive detection** toggle.
1. Select **Save changes**.

When you allow false positive detection for the group and turn it on for the project, the feature work works automatically with your existing SAST scanners.

## Confidence scores

The confidence score estimates how likely the GitLab Duo assessment is to be correct:

- **Likely false positive (80-100%)**: GitLab Duo is highly confident that the finding is a false positive.
- **Possible false positive (60-79%)**: GitLab Duo has reasonable confidence that the finding may be a false positive but recommends manual review.
- **Likely not a false positive (<60%)**: GitLab Duo is not confident that the finding is a false positive. Manual review is strongly recommended before you dismiss the vulnerability.

## Dismissing false positives

When the GitLab Duo analysis identifies a vulnerability as a false positive, you have the following options:

- Dismiss the vulnerability
- Remove the false positive flag

### Dismiss the vulnerability

1. On the top bar, select **Search or go to** and find your project.
1. Select **Secure** > **Vulnerability report**.
1. Select the vulnerability you want to dismiss.
1. Select **Change status**.
1. From the **Status** dropdown list, select **Dismissed**.
1. From the **Set dismissal reason** dropdown list, select **False positive**.
1. In the **Add a comment** input, provide context about why you're dismissing it as a false positive.
1. Select **Change status**.

The vulnerability is marked as dismissed and does not appear in future scans unless it is reintroduced.

### Remove the false positive flag

If you want to remove the false positive assessment and keep the vulnerability:

1. On the top bar, select **Search or go to** and find your project.
1. Select **Secure** > **Vulnerability report**.
1. Locate the vulnerability with the false positive flag.
1. Hover over the false positive badge on the vulnerability.
1. Select **Remove False Positive Flag**.

The false positive flag is removed and the FP confidence score reverts to 0. The vulnerability remains in the report and can be re-evaluated in future scans.

## Providing feedback

False positive detection is a beta feature and we welcome your feedback. If you encounter issues or have suggestions for improvement, please provide feedback in [issue 583697](https://gitlab.com/gitlab-org/gitlab/-/issues/583697).

## Related topics

- [Vulnerability details](_index.md)
- [Vulnerability report](../vulnerability_report/_index.md)
- [SAST](../sast/_index.md)
- [GitLab Duo](../../gitlab_duo/_index.md)
