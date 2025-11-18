---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Authentication and authorization best practices
description: Security recommendations and best practices for authentication, authorization, and access management.
---

Follow these security best practices to protect your GitLab instance and maintain proper access
controls. These recommendations help you maintain secure access without limiting productivity
across your organization.

## Security principles

Establish fundamental security principles that form the foundation of your access control strategy.

### Principle of least privilege

This principle reduces security risks by limiting potential damage from compromised accounts or insider threats.

- Grant users the minimum permissions necessary to complete their work.
- Assign minimum roles (Minimal Access or Guest) at the top-level group, then grant higher
permissions only in specific subgroups and projects where needed.
- Minimize the number of Owners and Maintainers by implementing custom roles that restrict access
to sensitive settings.
- When creating tokens, use the most limited scope possible or create multiple tokens with
different scopes for specific purposes.

### Hierarchical permission management

Organize permissions to match your organizational structure and reduce administrative overhead.

- Apply group membership permissions rather than project membership permissions when possible to reduce
administrative overhead.
- Create a single top-level group for your organization to enable centralized access control
and reporting.
- Organize your group hierarchy to match your organizational structure with clear ownership
boundaries.

### Defense in depth

Layer multiple security controls to protect against various types of attacks and failures.
If one control fails, others provide backup protection.

- Set up [protected branches](../user/project/repository/branches/protected.md) for critical
applications to prevent unauthorized changes.
- Configure [protected environments](../ci/environments/protected_environments.md) to restrict
deployments to specific roles or users.
- Use [protected containers](../user/packages/container_registry/container_repository_protection_rules.md)
to add extra security for sensitive artifacts.

## Authentication and credentials

Implement strong authentication methods to prevent unauthorized access to your GitLab instance.

### Password security

Passwords remain a primary authentication method despite their limitations. Strong password
policies reduce the risk of credential-based attacks by requiring strong passwords that meet
your organization's security standards.

- Configure [password length limits](../security/password_length_limits.md) appropriate for
your security requirements.
- Enable [compromised password detection](../security/compromised_password_detection.md) to
prevent the use of known compromised passwords.

### Two-factor authentication

Two-factor authentication (2FA) significantly improves security by requiring a second form
of verification. Even if passwords are compromised, 2FA prevents unauthorized access.

- Require [two-factor authentication](../user/profile/account/two_factor_authentication.md)
for all users, especially those with elevated permissions.
- Provide clear documentation and support for 2FA setup to ensure user adoption.
- Implement backup recovery methods to prevent account lockouts.

### Token-based authentication

Tokens provide secure, programmatic access to GitLab resources. Different token types serve
different purposes and have varying security implications.

- Rotate [personal access tokens](../user/profile/personal_access_tokens.md) regularly and
before they expire.
- Use [group access tokens](../user/group/settings/group_access_tokens.md) and
[project access tokens](../user/project/settings/project_access_tokens.md) instead of
personal tokens for automated processes.
- Store tokens securely and never commit them to repositories.

### SSH key authentication

SSH keys provide secure, passwordless access to Git repositories. Proper key management
is essential for maintaining security.

- Use strong SSH key algorithms (at minimum, RSA 2048-bit or Ed25519).
- Configure [SSH key restrictions](../security/ssh_keys_restrictions.md) to enforce security
standards.
- Regularly audit and rotate SSH keys, especially for service accounts.

## Access management

Control who can access what resources and monitor those permissions over time. Effective access
management balances security requirements with operational efficiency.

### User type management

Different user types require different access levels based on their relationship to your organization and security requirements. Properly classifying users helps enforce appropriate access boundaries.

- Designate contractors and third parties as [external users](../administration/external_users.md)
to automatically restrict their visibility to internal projects.
- Assign the Guest role to external collaborators who need limited interaction with repositories.
- Use [auditor users](../administration/auditor_users.md) for compliance and security personnel
who need read-only access across the instance.

### Regular access reviews

Periodic access reviews ensure user permissions remain appropriate as roles and responsibilities change over time. Regular reviews help identify and remediate inappropriate access before it becomes a security risk.

- Conduct regular access reviews to validate user permissions and resolve discrepancies immediately.
- Use [user export](../administration/admin_area.md#user-permission-export) and
[group export](../user/group/manage.md#export-members-as-csv) features to generate
comprehensive access reports.
- Remove access immediately when users leave the organization or change roles.

### Access monitoring and auditing

Continuous monitoring of access patterns and permission changes helps detect security incidents and maintain compliance. Audit trails provide visibility into who accessed what resources and when.

- Configure [audit event streaming](../administration/compliance/audit_event_streaming.md) to a SIEM tool for real-time security monitoring.
- Review [credentials inventory](../user/group/credentials_inventory.md) regularly to identify
unused or overprivileged tokens.
- Monitor for unauthorized access changes or privilege escalations.

## Organizational scaling

Different organizational sizes and structures require different approaches to permission
management. Adapt your access control practices to stay secure as you grow.

### Foundation level (1-50 users)

Focus on establishing good foundations without complex processes that could impede productivity.

- Start with default roles and assign permissions at the group level instead of per project.
- Document your permission decisions and rationale for future reference.
- Train your core team on the GitLab permission model and security practices.
- Establish group-level CI/CD configuration to enforce consistent security practices.

### Growth level (50-200 users)

Balance security requirements with the need for scalable processes.

- Integrate [LDAP](../user/group/access_and_permissions.md#manage-group-memberships-with-ldap)
or [SAML](../user/group/saml_sso/group_sync.md) with user groups to simplify management.
- Create separate subgroups for shared resources and sensitive resources to control access.
- Develop formal onboarding and offboarding processes for team members.
- Minimize deeply nested group structures (limit to 4-5 levels for most organizations).

### Enterprise level (200+ users)

Implement enterprise-grade controls and governance processes.

- Develop [custom roles](../user/custom_roles/_index.md) for unique access needs while reducing the
number of highly privileged users.
- Automate bulk access operations using GitLab APIs to reduce manual provisioning overhead.
- Establish governance processes for permission changes to prevent business disruption.
- Implement time-bound access for privileged roles and compliance frameworks for separation
of duties.

## Repository and CI/CD security

Protect your code, deployments, and automated processes from unauthorized changes and access.
These controls ensure the integrity of your software development and delivery pipeline.

### Pipeline security

CI/CD pipelines often have elevated privileges to deploy applications and access sensitive resources. Securing pipeline execution prevents unauthorized actions and protects your deployment process.

- Use [job permissions](../ci/jobs/fine_grained_permissions.md) to control what resources
are accessible during pipeline execution.
- Configure [approval gates](../ci/environments/deployment_approvals.md) for critical
deployment stages.
- Use environment-specific runners or runner tags to isolate deployments and limit access
to sensitive production resources.

### Repository protection

Source code repositories contain your organization's intellectual property and need protection from unauthorized changes. Repository security controls ensure code integrity and prevent malicious modifications.

- Implement [push rules](../user/project/repository/push_rules.md) to enforce commit standards
and prevent sensitive data exposure.
- Require [code review](../user/project/merge_requests/approvals/rules.md) through approval
rules before merging changes to protected branches.
- Use [signed commits](../user/project/repository/signed_commits/_index.md) to provide
cryptographic verification of commit authenticity.

### API and automation security

Automated processes and API integrations often use long-lived credentials with broad access. These non-human access patterns require special security considerations to prevent credential abuse.

- Use service accounts with limited permissions for automated processes rather than personal
tokens.
- Regularly rotate credentials used in automation and CI/CD pipelines.
- Monitor automated access patterns for unusual behavior or privilege escalation attempts.
- Use the most specific scopes possible when creating tokens for API access.
- Implement error handling and logging for API integrations.
- Rate limit API requests to prevent abuse and ensure system stability.
