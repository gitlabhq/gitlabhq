---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Learn how to apply security policies across multiple groups and projects from a single, centralized location.
title: Compliance and security policy groups
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/7622) in GitLab 18.2 [with a feature flag](../../../../administration/feature_flags/_index.md) named `security_policies_csp`. Disabled by default.
- [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/550318) on GitLab Self-Managed in GitLab 18.3.
- [Generally available](https://gitlab.com/groups/gitlab-org/-/epics/17392) in GitLab 18.5. Feature flag `security_policies_csp` removed.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is subject to change and may not ready for production use.

{{< /alert >}}

Centralized security policy management allows instance administrators to designate a compliance and security policy group to apply security policies across multiple groups and projects from a single, centralized location.

When you create or edit a security policy in the compliance and security policy group, you can scope the group to enforce the policy on:

- **Specific groups and subgroups**: Apply the policy only to selected groups and their subgroups.
- **Specific projects**: Apply the policy to individual projects.
- **All projects in the instance**: Apply the policy across your entire GitLab instance.
- **All projects with exceptions**: Apply to all projects except those you specify.

When you designate a compliance and security policy group to serve as your centralized policy management hub, you can:

- Create and configure security policies that automatically apply across your instance.
- Scope policies to specific groups, projects, or your entire instance.
- View comprehensive policy coverage to understand which policies are active and where they're active.
- Maintain centralized control while allowing teams to create their own additional policies.

## Prerequisites

- GitLab Self-Managed.
- GitLab 18.2 or later.
- You must be instance administrator.
- You must have an existing top-level group to serve as the compliance and security policy group.
- To use the REST API (optional), you must have a token with administrator access.

## Set up centralized security policy management

To set up centralized security policy management, you designate a compliance and security policy group and then create policies in the group.

For more information, see [instance-wide compliance and security policy management](../../../../security/compliance_security_policy_management.md).

### Enable global approval groups

To support approval groups globally across your instance, you must:

- Enable `security_policy_global_group_approvers_enabled` in your [GitLab instance application settings](../../../../api/settings.md).

### Create security policies in the compliance and security policy group

To create the policies:

1. Go to your designated compliance and security policy group.
1. Go to **Secure** > **Policies**.
1. Create one or more security policies as you typically would. Before you save each policy:
   - In the **Policy scope** section, select a scope to apply the policy to:
      - **Groups**: Apply the policy to specific groups and subgroups.
      - **Projects**: Apply the policy individual projects.
      - **All projects**: Apply to the entire instance.
      - **All projects except**: Apply to all projects with specified exceptions.
1. Save your policy configuration.

## Policy storage and configuration

Policies in a compliance and security policy group are stored in a `policy.yml` file in the designated compliance and security policy group, similar to how group policies are managed. Policies created in a compliance and security policy group use the same configuration format as security policies in other groups and projects.

## Policy synchronization

- Depending on the number of groups and projects in scope, policy changes may take some time to apply across your instance.
- The synchronization process uses background jobs that are automatically queued when you designate a compliance and security policy group, create policies, or update policies.
- Instance administrators can monitor background job processing in **Admin Area** > **Monitoring** > **Background jobs**.
- To verify that policies are successfully applied in a target group or project, go to **Secure** > **Policies** in the group or project.

### Managing performance

To prevent performance issues, plan your policy management strategy to minimize the number of modifications to your configuration:

- Plan changes carefully: Avoid making multiple compliance and security policy group changes in quick succession.
- Schedule changes during maintenance windows: Make changes during low-usage periods to minimize the impact on users.
- Monitor system performance: Be prepared for potential performance degradation during synchronization.
- Allow extra time: The synchronization process completion time depends on your instance size.

## Troubleshooting

**Policy does not appear in the target group or project**

- Verify that the policy scope includes the target group or project.
- Verify that the compliance and security policy group is properly designated in the admin settings.
- Verify that the policy is enabled in the compliance and security policy group.
- Policy changes may take time to be applied. See [policy synchronization](#policy-synchronization) for more information.

**Performance concerns**

- Monitor policy propagation times, especially with large scope configurations.
- Consider scoping policies to specific groups or projects instead of applying the policies to all projects.
- To reduce performance impacts when modifying compliance security policy groups, see [managing performance](#managing-performance).

## Feedback and support

As this is a Beta release, we actively seek feedback from users. Share your experience, suggestions, and any issues through:

- [GitLab Issues](https://gitlab.com/gitlab-org/gitlab/-/issues).
- Your regular GitLab support channels.
