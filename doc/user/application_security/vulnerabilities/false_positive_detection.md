---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Detect false positives automatically
description: Automatic detection and filtering of false positives in SAST findings.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/18977) in GitLab 18.7 as a [beta](../../../policy/development_stages_support.md#beta) [with feature flags](../../../administration/feature_flags/_index.md) named `enable_vulnerability_fp_detection` and `ai_experiment_sast_fp_detection`. Enabled by default.
- [Generally available](https://gitlab.com/groups/gitlab-org/-/work_items/19789) in GitLab 18.10.
- Feature flags [`ai_experiment_sast_fp_detection`](https://gitlab.com/gitlab-org/gitlab/-/work_items/584344) and [`enable_vulnerability_fp_detection`](https://gitlab.com/gitlab-org/gitlab/-/work_items/584343) removed in GitLab 19.1.

{{< /history >}}

When a static application security testing (SAST) scan runs, the SAST False Positive Detection Flow automatically analyzes each Critical and High severity SAST vulnerabilities to determine the likelihood that it's a false positive. Detection is available for vulnerabilities from [GitLab-supported SAST analyzers](../sast/analyzers.md).

The flow assessment includes:

- Confidence score: A numerical score indicating the likelihood that the finding is a false positive.
- Explanation: Contextual reasoning about why the finding may or may not be a true positive, based on code context and vulnerability characteristics.
- Visual indicator: A badge in the vulnerability report showing the false positive assessment.

The detection runs automatically after each security scan with no manual triggering required.

Results are based on AI analysis and should be reviewed by security professionals.

<i class="fa-youtube-play" aria-hidden="true"></i>
For an overview, see [GitLab AI-Powered SAST False Positive Detection and Remediation](https://www.youtube.com/watch?v=kVMM5OFva_U).
<!-- Video published on 2026-03-20 -->

For a click-through demo, see [SAST False Positive Detection Flow](https://gitlab.navattic.com/sast-fp-detection-flow).
<!-- Demo published on 2026-02-17 -->

## Prerequisites

- Meet the [prerequisites for the GitLab Duo Agent Platform](../../duo_agent_platform/_index.md#prerequisites).
- Turn on **Allow foundational flows** and **SAST False Positive Detection** [for the top-level group](../../duo_agent_platform/flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off).
- [Configure push rules to allow a service account](../../duo_agent_platform/troubleshooting.md#configure-push-rules-to-allow-a-service-account).
- [Configure your own runners](../../duo_agent_platform/flows/execution/_index.md#configure-runners-to-execute-flows) or turn on [GitLab hosted runners](../../../ci/runners/hosted_runners/_index.md) for your project.
- Set [a default GitLab Duo namespace](../../profile/preferences.md#set-a-default-gitlab-duo-namespace) in your user preferences.

## Allow foundational flow for a group

You can allow all projects in a group to use the foundational flow. Individual projects must still enable the feature in their project settings.
To allow false positive detection for all projects in a group:

1. In the left sidebar, select **Search or go to** and find your group.
1. Select **Settings** > **GitLab Duo**.
1. Under **Allow foundational flows**, select the **SAST False Positive Detection** checkbox.
1. Select **Save changes**.

## Turn on for a project

Prerequisites:

- The Security Manager, Maintainer, or Owner role for the project.

To turn on false positive detection for a specific project:

1. In the left sidebar, select **Search or go to** and find your project.
1. Select **Settings** > **General**.
1. Expand **GitLab Duo**.
1. Turn on the **Turn on SAST false positive detection** toggle.
1. Select **Save changes**.

When you allow false positive detection for the group and turn it on for the project, the feature work works automatically with your existing SAST scanners.

## Automatic detection

The false positive detection flow runs automatically when:

- A SAST security scan completes successfully on the default branch.
- The scan detects Critical or High severity vulnerabilities.
- GitLab Duo features are enabled for the project.

The analysis happens in the background and results appear in the vulnerability report after processing is complete.

## Run the SAST False Positive Detection Flow

You can manually trigger analysis for existing vulnerabilities:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Secure** > **Vulnerability report**.
1. Select the vulnerability you want to analyze.
1. In the upper-right corner, select **AI actions**, then select **Check for false positive**.

The GitLab Duo analysis runs and results are displayed on the vulnerability details page.

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

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Secure** > **Vulnerability report**.
1. Select the vulnerability you want to dismiss.
1. In the right sidebar, in the **Status** section, select **Edit**.
1. From the **Status** dropdown list, under **Dismiss as...**, select **False positive**.
1. In the **Comment** text box, provide context about why you're dismissing it as a false positive.
   A comment is required.
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

Share your feedback in [issue 583697](https://gitlab.com/gitlab-org/gitlab/-/issues/583697).

## Related topics

- [Vulnerability details](_index.md)
- [Vulnerability report](../vulnerability_report/_index.md)
- [SAST](../sast/_index.md)
- [GitLab Duo](../../gitlab_duo/_index.md)
