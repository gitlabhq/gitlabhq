---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Learn how to manage compliance frameworks across your entire GitLab instance from a single, centralized location.
title: Centralized compliance frameworks
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/15864) in GitLab 18.3 [with feature flags](../../../administration/feature_flags/_index.md) named `security_policies_csp` and `include_csp_frameworks`. Enabled by default.
- Feature flag `security_policies_csp` [removed](https://gitlab.com/groups/gitlab-org/-/epics/17392) in GitLab 18.5.
- [Generally available](https://gitlab.com/groups/gitlab-org/-/epics/15864) in GitLab 18.6. Feature flag `include_csp_frameworks` removed.

{{< /history >}}

Centralized security compliance frameworks management allows GitLab administrators to centrally manage and enforce
compliance requirements across all groups and projects in a GitLab instance.

By designating a compliance and security policy (CSP) group, you can create compliance frameworks that are automatically
available to all top-level groups.

When you designate a compliance and security policy group:

- All compliance frameworks created in the compliance and security policy group become available to every top-level group in your instance.
- Group owners can assign these centralized frameworks to their projects.
- The frameworks appear alongside any group-specific frameworks, with clear indicators showing they come from the compliance and security policy
  group.
- Compliance and security policy frameworks are read-only for non-members of the compliance and security policy group, ensuring consistent application of compliance standards.

Framework visibility and permissions:

- All users can see which frameworks are applied to projects they have access to.
- Group members can view all compliance and security policy frameworks available to their group.
- The compliance center shows both compliance and security policy group frameworks and group-specific frameworks.

## Prerequisites

- You must be an administrator.
- An existing top-level group to serve as the compliance and security policy group.
- To use the REST API (optional), you must have a token with administrator access.

## Before you begin

Before you begin, designate a top-level group as your compliance and security policy group to serve as the central location for managing compliance
frameworks.

For detailed instructions, see
[Designate a compliance and security policy group](../../../security/compliance_security_policy_management.md#designate-a-compliance-and-security-policy-group).

## Create compliance frameworks in the compliance and security policy group

After you've designated a compliance and security policy group, create compliance frameworks in it:

1. Go to your designated compliance and security policy group.
1. Select **Secure** > **Compliance center**.
1. On the page, select the **Frameworks** tab.
1. Select **New framework**.
1. Enter the framework details:
   - **Name**: A descriptive name for the framework.
   - **Description**: Explain the purpose and requirements of the framework.
   - **Color**: Choose a color for visual identification.
   - **Requirements** (optional): Add specific controls and requirements.
1. Select **Save changes**.

The framework is now available to all top-level groups in your instance.

## Configure framework requirements (optional)

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

You can define specific requirements and controls for each compliance framework:

1. When creating or editing a framework in the compliance and security policy group, go to the **Requirements** section.
1. Select **New requirement**.
1. Add one or more controls:
   - **GitLab controls**: Pre-defined checks for GitLab features and settings.
   - **External controls**: Integration with third-party compliance tools.
1. Select **Save changes to the framework**.

For more information about available controls, see [GitLab compliance controls](_index.md#gitlab-compliance-controls)
and details of [supported compliance standards](compliance_standards.md).

## Apply compliance and security policy frameworks to projects

Apply compliance and security policy frameworks to projects as either a group owner or a project owner.

### As a group owner

Group owners can view and apply compliance and security policy frameworks to their projects. Compliance and security policy frameworks are read-only on groups and you
cannot edit or delete them from your group.

To apply a compliance and security policy framework to projects in your group:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Secure** > **Compliance center**.
1. On the page, select the **Projects** tab.
1. Compliance and security policy frameworks appear in the list with a special indicator.
1. Select a compliance and security policy framework to apply it to projects in your group.

### As a project owner

To see which compliance frameworks apply to your projects:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **General**.
1. Expand the **Compliance frameworks** section.
1. View all applied frameworks, including those from the compliance and security policy group.

## Modifying compliance and security policy frameworks

When you modify a compliance framework in the compliance and security policy group:

- Changes are immediately reflected across all groups.
- Projects using the framework automatically inherit the updates.
- Audit events track all modifications.
- No action is required from group or project owners.

## Deleting compliance and security policy frameworks

When you delete a compliance and security policy framework, GitLab displays a warning about affected projects.

When you confirm that you want a compliance and security policy framework deleted:

- The framework is removed from all projects.
- Audit events are generated.
- The framework is no longer visible in any group.

## Changing the compliance and security policy group

If you need to change which group serves as the compliance and security policy group:

- All frameworks from the previous compliance and security policy group become unavailable.
- Frameworks from the new compliance and security policy group become available.
- Projects must be reassigned to new frameworks if needed.

For detailed instructions, see
[designate a compliance and security policy group](../../../security/compliance_security_policy_management.md#designate-a-compliance-and-security-policy-group).

## Integration with security policies

Compliance and security policy frameworks can be integrated with security policies for enhanced compliance:

1. Create security policies in the compliance and security policy group.
1. Scope policies to specific compliance frameworks.
1. Projects with those frameworks automatically inherit the policies.

For more information, see [security policy management in the compliance and security policy group](../../application_security/policies/enforcement/compliance_and_security_policy_groups.md).

## Troubleshooting

Possible solutions to issues you might encounter using centralized compliance frameworks.

### Frameworks not appearing in groups

If compliance and security policy frameworks aren't visible in your groups:

1. Verify the compliance and security policy group is properly designated in Admin settings.
1. Check that frameworks exist in the compliance and security policy group.
1. Ensure you have appropriate permissions to view frameworks.

### Cannot modify compliance and security policy frameworks

Compliance and security policy frameworks can only be modified from the compliance and security policy group:

1. Go the compliance and security policy group directly.
1. Ensure you have the Owner role on the compliance and security policy group.
1. Make changes from the compliance and security policy group's Compliance center.

## Feedback and support

Because this feature is in [beta](../../../policy/development_stages_support.md#beta), we actively seek feedback from users.
Share your experience, suggestions, and any issues through:

- [GitLab issues](https://gitlab.com/gitlab-org/gitlab/-/issues).
- Your regular GitLab support channels.

## Related topics

- [Instance-wide compliance and security policy management](../../../security/compliance_security_policy_management.md)
- [Compliance frameworks](_index.md)
- [Compliance and security policy groups](../../application_security/policies/enforcement/compliance_and_security_policy_groups.md)
- [Compliance center](../compliance_center/_index.md)
