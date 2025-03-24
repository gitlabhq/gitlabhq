---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Compliance features for administrators
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

GitLab compliance features for administrators ensure your GitLab instance meets common compliance standards. Many
of the features are also available for groups and projects.

## Compliant workflow automation

It is important for compliance teams to be confident that their controls and
requirements are set up correctly, but also that they _stay_ set up correctly.
One way of doing this is manually checking settings periodically, but this is
error prone and time consuming. A better approach is to use single-source-of-truth
settings and automation to ensure that whatever a compliance team has configured,
stays configured and working correctly. These features can help you automate
compliance:

| Feature                                                                                                                                       | Instances                             | Groups                               | Projects                              | Description |
|:----------------------------------------------------------------------------------------------------------------------------------------------|:--------------------------------------|:-------------------------------------|:--------------------------------------|:------------|
| [Merge request approval policy approval settings](../../user/application_security/policies/merge_request_approval_policies.md#approval_settings) | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | Enforce a merge request approval policy enforcing multiple approvers and override various project settings in all enforced groups or projects across your GitLab instance or group. |

## Audit management

An important part of any compliance program is being able to go back and understand
what happened, when it happened, and who was responsible. You can use this in audit
situations as well as for understanding the root cause of issues when they occur.

It is helpful to have both low-level, raw lists of audit data as well as high-level,
summary lists of audit data. Between these two, compliance teams can quickly
identify if problems exist and then drill down into the specifics of those issues.
These features can help provide visibility into GitLab and audit what is happening:

| Feature                                                  | Instances                            | Groups                               | Projects                             | Description |
|:---------------------------------------------------------|:-------------------------------------|:-------------------------------------|:-------------------------------------|:------------|
| [Audit events](audit_event_reports.md)                   | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | To maintain the integrity of your code, audit events give administrators the ability to view any modifications made in the GitLab server in an advanced audit events system, so you can control, analyze, and track every change. |
| [Audit reports](audit_event_reports.md)                  | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | Create and access reports based on the audit events that have occurred. Use pre-built GitLab reports or the API to build your own. |
| [Audit event streaming](audit_event_streaming.md) | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | Stream GitLab audit events to a HTTP endpoint or third party service, such as AWS S3 or GCP Logging. |
| [Auditor users](../auditor_users.md)                        | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | Auditor users are users who are given read-only access to all projects, groups, and other resources on the GitLab instance. |

## Policy management

Organizations have unique policy requirements, either due to organizational
standards or mandates from regulatory bodies. The following features help you
define rules and policies to adhere to workflow requirements, separation of duties,
and secure supply chain best practices:

| Feature                                                                       | Instances                            | Groups                               | Projects                             | Description |
|:------------------------------------------------------------------------------|:-------------------------------------|:-------------------------------------|:-------------------------------------|:------------|
| [Credentials inventory](../credentials_inventory.md)                             | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | Keep track of the credentials used by all of the users in a GitLab instance. |
| [Granular user roles<br/>and flexible permissions](../../user/permissions.md)    | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | Manage access and permissions with five different user roles and settings for external users. Set permissions according to people's role, rather than either read or write access to a repository. Don't share the source code with people that only need access to the issue tracker. |
| [Merge request approvals](../../user/project/merge_requests/approvals/_index.md) | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | Configure approvals required for merge requests. |
| [Push rules](../../user/project/repository/push_rules.md)                        | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | Control pushes to your repositories. |
| [Security policies](../../user/application_security/policies/_index.md)          | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | Configure customizable policies that require merge request approval based on policy rules, or enforce security scanners to execute in project pipelines for compliance requirements. Policies can be enforced granularly against specific projects, or all projects in a group or subgroup. |

## Other compliance features

These features can also help with compliance requirements:

| Feature                                                                                                                         | Instances                            | Groups                               | Projects                             | Description |
|:--------------------------------------------------------------------------------------------------------------------------------|:-------------------------------------|:-------------------------------------|:-------------------------------------|:------------|
| [Email all users of a project,<br/>group, or entire server](../email_from_gitlab.md)                                               | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | Email groups of users based on project or group membership, or email everyone using the GitLab instance. These emails are great for scheduled maintenance or upgrades. |
| [Enforce ToS acceptance](../settings/terms.md)                                                                                     | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | Enforce your users accepting new terms of service by blocking GitLab traffic. |
| [Generate reports on permission<br/>levels of users](../admin_area.md#user-permission-export)                                      | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | Generate a report listing all users' access permissions for groups and projects in the instance. |
| [LDAP group sync](../auth/ldap/ldap_synchronization.md#group-sync)                                                                 | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | Automatically synchronize groups and manage SSH keys, permissions, and authentication, so you can focus on building your product, not configuring your tools. |
| [LDAP group sync filters](../auth/ldap/ldap_synchronization.md#group-sync)                                                         | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | Gives more flexibility to synchronize with LDAP based on filters, meaning you can leverage LDAP attributes to map GitLab permissions. |
| [Linux package installations support<br/>log forwarding](https://docs.gitlab.com/omnibus/settings/logs.html#udp-log-forwarding) | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | Forward your logs to a central system. |
| [Restrict SSH Keys](../../security/ssh_keys_restrictions.md)                                                                       | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | Control the technology and key length of SSH keys used to access GitLab. |

## Related topics

- [Software Compliance with GitLab](https://about.gitlab.com/solutions/compliance/)
- [Secure GitLab](../../security/_index.md)
- [Compliance features for users](../../user/compliance/_index.md)
