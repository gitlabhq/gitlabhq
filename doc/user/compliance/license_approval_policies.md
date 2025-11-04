---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: License approval policies
description: Understand how to specify criteria using license approval policy for approval of a merge request before it can be merged. Applies to protected target branches only.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/8092) in GitLab 15.9 [with a flag](../../administration/feature_flags/_index.md) named `license_scanning_policies`.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/397644) in GitLab 15.11. Feature flag `license_scanning_policies` removed.

{{< /history >}}

Use license approval policies to specify criteria that determines when approval is required before a merge request can be merged.

License approval policies apply only to [protected](../project/repository/branches/protected.md) target branches.

The following video provides an overview of these policies.

<div class="video-fallback">
  See the video: <a href="https://www.youtube.com/watch?v=34qBQ9t8qO8">Overview of GitLab License Approval Policies</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/34qBQ9t8qO8" frameborder="0" allowfullscreen> </iframe>
</figure>

## Prerequisites to creating a new license approval policy

License approval policies rely on the output of a dependency scanning job to verify that requirements have been met. If dependency scanning has not been properly configured, and therefore no dependency scanning jobs ran related to an open MR, the policy has no data with which to verify the requirements. When security policies are missing data for evaluation, by default they fail closed and assume the merge request could contain vulnerabilities. You can opt out of the default behavior with the `fallback_behavior` property and set policies to fail open. A policy that fails open has all invalid and unenforceable rules unblocked.

To ensure enforcement of your policies, you should enable dependency scanning on your target development projects. You can achieve this a few different ways:

- Create a [scan execution policy](../application_security/policies/scan_execution_policies.md) that enforces dependency scanning to run in all target development projects.
- Work with your development teams to configure [dependency scanning](../application_security/dependency_scanning/_index.md) in each of their projects' `.gitlab-ci.yml` files or enable it using a [security configuration](../application_security/detect/security_configuration.md).

License approval policies require license information from [GitLab-supported packages](license_scanning_of_cyclonedx_files/_index.md#supported-languages-and-package-managers).

## Create a new license approval policy

Create a license approval policy to enforce license compliance.

To create a license approval policy:

1. [Link a security policy project](../application_security/policies/enforcement/security_policy_projects.md#link-to-a-security-policy-project) to your development group, subgroup, or project (the Owner role is required).
1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Secure** > **Policies**.
1. Create a new [merge request approval policy](../application_security/policies/merge_request_approval_policies.md).
1. In your policy rule, select **License scanning**.

## Criteria defining which licenses require approval

The following types of criteria can be used to determine which licenses are "approved" or "denied" and require approval.

- When any license in a list of explicitly prohibited licenses is detected.
- When any license is detected except for licenses that have been explicitly listed as acceptable.

## Criteria to compare licenses detected in the merge request branch to licenses in the default branch

The following types of criteria can be used to determine whether or not approval is required based on the licenses that exist in the default branch:

- Denied licenses can be configured to only require approval if the denied license is part of a dependency that does not already exist in the default branch.
- Denied licenses can be configured to require approval if the denied license exists in any component that already exists in the default branch.

![License approval policy](img/license_approval_policy_v15_9.png)

If a license is found that violates the license approval policy, it blocks the merge request and instructs the developer to remove it. The merge request cannot be merged until the `denied` license is removed unless an eligible approver for the license approval policy approves the merge request.

![Merge request with denied licenses](img/denied_licenses_v15_3.png)

## Troubleshooting

### The license compliance widget is stuck in a loading state

A loading spinner is displayed in the following scenarios:

- While the pipeline is in progress.
- If the pipeline is complete, but still parsing the results in the background.
- If the license scanning job is complete, but the pipeline is still running.

The license compliance widget polls every few seconds for updated results. When the pipeline is complete, the first poll after pipeline completion triggers the parsing of the results. This can take a few seconds depending on the size of the generated report.

The final state is when a successful pipeline run has been completed, parsed, and the licenses displayed in the widget.

### License approval policies block merge requests due to `unknown` licenses

License approval policies may block merge requests due to `unknown` licenses in certain scenarios. This can happen in
any of the following situations:

- The dependency scanning job fails to identify a license for a particular component.
- A new or uncommon license is used that is not recognized by the scanning tool.
- The license information is missing or incomplete in the component's metadata.

To address this issue:

1. Review the **Licenses** tab in the pipeline page to identify which components have `unknown` licenses or review `out-of-policy` licenses generated by the GitLab security bot.
1. Manually investigate these components to determine their actual licenses.
1. If the licenses cannot be determined or are not acceptable, consider removing or replacing the affected components.

If you need to temporarily allow merging with `unknown` licenses:

1. Edit your license approval policy.
1. Add `unknown` to the list of allowed licenses.
1. After addressing the issue, remember to remove `unknown` from the allowed licenses list to maintain proper license compliance.

Always consult with your legal team when dealing with license compliance issues, especially when handling `unknown` licenses.
