---
stage: GitLab Dedicated
group: US Public Sector Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>.
title: GitLab Dedicated for Government secure configuration guide 
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated for Government

{{< /details >}}

FedRAMP requires Cloud Service Providers to create, maintain, and publish a
[secure configuration guide](https://www.fedramp.gov/docs/rev5/balance/secure-configuration-guide/).
The mandate includes both required and recommended criteria. Use this page to harden your
Dedicated for Government instance and align with the latest FedRAMP guidance.

Required criteria:

- Instructions on how to securely access, configure, operate, and decommission top-level
  administrator accounts that control enterprise access to the entire cloud service offering.
- Explanations of security-related settings that can be operated only by top-level
  administrator accounts and their security implications.

Recommended criteria:

- Explanations of security-related settings that can be operated only by privileged accounts
  and their security implications.
- Secure defaults for top-level administrator accounts and privileged accounts when initially
  provisioned.

GitLab has an expansive set of configuration guidance available for US federal agencies and
organizations serving the public sector.
With [transparency as a core value](https://handbook.gitlab.com/handbook/values/#transparency),
the [GitLab documentation](https://docs.gitlab.com) already addresses the required elements
of the secure configuration guide in detail.

## Architecture

[GitLab Dedicated for Government](../subscriptions/gitlab_dedicated_for_government/_index.md)
is a single-tenant SaaS solution purpose-built for government agencies. It holds a
[FedRAMP Moderate Authority to Operate (ATO)](https://marketplace.fedramp.gov/products/FR2411959145),
runs on AWS GovCloud, and provides full infrastructure-level isolation. Each customer
environment lives in a dedicated AWS account, separated from other tenants.

The architecture has two distinct administrative layers:

Infrastructure management layer
: Managed by GitLab.

Application administration layer
: Controlled by customer administrators.

Before reviewing the configuration settings in this guide, review the
[shared responsibility model](dedicated_for_government_shared_responsibility_model.md) for GitLab Dedicated for Government.
The shared responsibility model is the foundation for understanding what hardening must be
applied by federal agency administrators.

## Requirement 1: Top-level administrator account lifecycle

This section covers the full lifecycle of top-level administrator accounts, from secure
setup and day-to-day operation to safe decommission.

FedRAMP requirement: Explain how to securely access, configure, operate, and
decommission top-level administrative accounts that control enterprise access to the entire
cloud service offering.

### Access lifecycle

When you purchase a GitLab Dedicated for Government instance, the GitLab Dedicated team
provisions your initial top-level administrator account. Dedicated engineers then assist
you with configuring an integration with an identity management solution. Once configured,
you have full control over administering access to your instance.

GitLab Dedicated for Government supports
[SAML and OpenID Connect (OIDC)](../subscriptions/gitlab_dedicated_for_government/_index.md#authentication-and-authorization)
for single sign-on, so you can route administrative authentication through your existing
government identity infrastructure. You are responsible for integrating an identity provider
to meet all relevant PIV/CAC requirements for FedRAMP.

For the full access lifecycle, see:

- [Add users](../user/profile/account/create_accounts.md#create-a-user-with-an-authentication-integration)
- [Remove or delete users](../user/profile/account/delete_account.md#delete-users-and-user-contributions)

Administrators can add and remove other administrators as required. GitLab recommends either
creating dedicated administrator accounts or turning on
[Admin mode](../administration/settings/sign_in_restrictions.md#admin-mode), a built-in
security control that requires administrators to explicitly elevate their session before
accessing the Admin area. Either approach ensures that privileged accounts are used only for
their corresponding privileged functions.

Once your identity platform is integrated, the top-level administrator can provision users to
build out the initial user base. Apply the principle of least privilege for all user accounts.
Once projects are established, access can be assigned to specific users through the following
roles at the project level:

- Minimal Access
- Guest
- Planner
- Reporter
- Developer
- Maintainer
- Owner

GitLab also supports the following user types for unique use cases:

- [Auditor users](../administration/auditor_users.md): Provides read-only access to all
  groups, projects, and other resources except the Admin area and project or group settings.
  Use the auditor role when engaging with third-party auditors that require access to certain
  projects to validate processes.
- [External users](../administration/external_users.md): Provides limited access for users
  outside your organization, such as contractors or other third parties. Controls such as
  IA-4(4) require non-organizational users to be identified and managed in accordance with
  company policy. Setting external users reduces risk by limiting access to projects by
  default and helping administrators identify users not employed by the organization.
- [Service accounts](../user/profile/service_accounts.md): Accommodates automated tasks.
  Service accounts do not use a seat under the license.

GitLab supports [custom roles](../user/custom_roles/_index.md) for unique permission
requirements. For more information, see
[project permissions](../user/permissions.md#project-permissions) and
[group permissions](../user/permissions.md#group-permissions).

Once sufficient user structure is established with administrators provisioned in your identity
platform, treat the top-level administrator account as a break-glass account, with all other
administrative activities occurring through your standard identity provider.

## Requirement 2

FedRAMP Requirement: **Provide explanations of security-related settings that can be operated only by top-level administrative accounts and their security implications.**

This section of the Secure Configuration Guide will enumerate configuration settings specifically available to Dedicated for Government and point customers to the broad documentation already available for [administering GitLab](../administration/_index.md). 

### Dedicated for Government infrastructure configurations by top-Level administrators

GitLab Dedicated for Government allows for specific infrastructure-level security and architecture configurations to be requested by top-level customer administrators, triggered through requests to the GitLab Support team. 

These configurations include: 

- Establishing network connectivity with resources outside of the tenant, i.e. via PrivateLink. 
- Bringing customer-supplied keys (Bring-Your-Own-Key) - Customers can request that the GitLab tenant uses customer-supplied keys. 
- Setting Custom Domains - Customers can request that the GitLab tenant uses a customer-supplied domain, rather than the standard Dedicated for Government domain. It is the customer's responsibility to ensure that the supplied domain meets all relevant mandates for DNSSEC. 
- Selecting a reference architecture
- Selecting a total repository capacity
- Selecting a tenant name
- Selecting availability zones
- Receiving license keys
- Setting root user passwords
- Selecting a release rollout/maintenance schedule
- Setting inbound and outbound IP/domain allowlists

## Recommendation 1

FedRAMP Recommendation: **Provide explanations of security-related settings that can be operated only by privileged accounts and their security implications.**

## Requirement 2: Security settings for top-level administrator accounts

Security settings available only to top-level administrators have direct implications for
the security posture of your entire instance.

FedRAMP requirement: Provide explanations of security-related settings that
can be operated only by top-level administrative accounts and their security implications.

### Infrastructure configurations for top-level administrators

GitLab Dedicated for Government supports specific infrastructure-level security and
architecture configurations that you can request through the GitLab Support team.

These configurations include:

- Network connectivity with resources outside of the tenant, for example through PrivateLink
- Customer-managed encryption: Request that the GitLab tenant uses customer-supplied
  encryption keys. You are responsible for creating and managing KMS keys and key policies.
- Custom domains: Request a customer-supplied domain rather than the standard Dedicated for
  Government domain. You are responsible for ensuring the domain meets all relevant mandates
  for DNSSEC.
- Reference architecture selection
- Total repository capacity
- Tenant name
- Availability zones
- License keys
- Root user passwords
- Release rollout and maintenance schedule
- Inbound and outbound IP and domain allowlists

## Recommendation 1: Security settings for privileged accounts

Privileged accounts below the top-level administrator have access to settings that can
significantly affect the security of your instance and its data.

FedRAMP recommendation: Provide explanations of security-related settings
that can be operated only by privileged accounts and their security implications.

The top-level administrator and administrator accounts provisioned through your identity
provider are functionally equivalent. Use the top-level account for initial setup only.
Use administrator accounts provisioned through your identity provider for all subsequent
security settings and configurations. For all available configurations, see
[Administer GitLab](../administration/_index.md).

### System development lifecycle and change management

Administrators have a broad suite of tools to secure the software development lifecycle
(SDLC) and establish change management practices. For more information, see
[build and manage code with CI/CD](../topics/build_your_application.md).

Review the [pipeline security](../ci/pipeline_security/_index.md) documentation to understand
how to design CI/CD pipelines with security in mind. The
[NIST 800-53 compliance guide](hardening_nist_800_53.md#configuration-management-cm) has
details on how to establish change control and secure branches. Review the available change
management configurations to ensure that only approved changes are applied to your codebase.

### Risk assessment and system and information integrity

You are responsible for establishing tools to secure your code. GitLab includes a suite of
[detection tools](../user/application_security/detect/_index.md) that you can incorporate
into the development of your applications, including:

- [Security configuration](../user/application_security/detect/security_configuration.md)
- [Container scanning](../user/application_security/container_scanning/_index.md)
- [Dependency scanning](../user/application_security/dependency_scanning/_index.md)
- [Static application security testing (SAST)](../user/application_security/sast/_index.md)
- [Infrastructure as Code (IaC) scanning](../user/application_security/iac_scanning/_index.md)
- [Secret detection](../user/application_security/secret_detection/_index.md)
- [Dynamic application security testing (DAST)](../user/application_security/dast/_index.md)
- [API fuzzing](../user/application_security/api_fuzzing/_index.md)
- [Coverage-guided fuzz testing](../user/application_security/coverage_fuzzing/_index.md)

You can enforce specific CI jobs to ensure all code is assessed for vulnerabilities before
being merged.

### Access management

The following roles have privileged functions beyond standard user access:

- Maintainer
- Owner

These roles have [extensive permissions documentation](../user/permissions.md) that requires
careful review when provisioning users to projects and groups.

#### Access management in the Admin area

In the Admin area, administrators can
[export permissions](../administration/admin_area.md#user-permission-export),
[review user identities](../administration/admin_area.md#user-identities),
[administer groups](../administration/admin_area.md#administering-groups), and more.
Functions useful for meeting FedRAMP and NIST 800-53 requirements include:

- [Reset user password](reset_user_password.md) when suspected of compromise.
- [Unlock users](unlock_user.md). By default, GitLab locks users after 10 failed sign-in
  attempts. Users remain locked for 10 minutes or until an administrator unlocks them.
  Per guidance in AC-7, FedRAMP defers to NIST 800-63B for defining parameters for account
  lockouts, which the default setting satisfies.
- Review [abuse reports](../administration/review_abuse_reports.md) or
  [spam logs](../administration/review_spam_logs.md). FedRAMP requires organizations to
  monitor accounts for atypical use (AC-2(12)). Users can flag abuse in abuse reports, where
  administrators can remove access pending investigation. Spam logs are consolidated in the
  **Spam logs** section of the Admin area. Administrators can remove, block, or trust users
  flagged in that area.
- [Credentials inventory](../administration/credentials_inventory.md): Review all secrets
  used in a GitLab instance in one place. A consolidated view of credentials, tokens, and
  keys can help satisfy requirements such as reviewing passwords or rotating credentials.
- [Default session durations](../administration/settings/account_and_limit_settings.md#customize-the-default-session-duration):
  FedRAMP requires that inactive users are logged out after a set time period. FedRAMP does
  not specify the time period, but clarifies that privileged users should be logged out at
  the end of the standard work period.
- [Provision new users](../user/profile/account/create_accounts.md): Create users through
  the Admin area UI. In compliance with IA-5, GitLab requires new users to change their
  passwords on first login.
- Deprovision users: [Remove users through the Admin area UI](../user/profile/account/delete_account.md#delete-users-and-user-contributions).
  Alternatively, [block a user](../administration/moderate_users.md#block-a-user) to remove
  all access while maintaining their data in repositories. Blocked users do not affect seat
  counts.
- Deactivate users: Inactive users identified during account reviews
  [can be temporarily deactivated](../administration/moderate_users.md#deactivate-a-user).
  Unlike blocking, deactivating a user does not prevent them from signing in to the GitLab
  UI. A deactivated user can become active again by signing in. A deactivated user:
  - Cannot access repositories or the API.
  - Cannot use slash commands.
  - Does not occupy a seat.

### SSH keys

GitLab [provides instructions](../user/ssh.md) on how to configure SSH keys to authenticate
and communicate with Git. [Commits can be signed](../user/project/repository/signed_commits/ssh.md),
providing additional verification for anyone with a public key. Administrators can
[establish minimum key technologies and key lengths](ssh_keys_restrictions.md).

You are responsible for ensuring that SSH keys are generated with FIPS-validated
cryptographic modules.

### Token management

GitLab [provides instructions](../user/profile/personal_access_tokens.md) on how to
configure and manage personal access tokens. GitLab supports
[fine-grained permissions](../auth/tokens/fine_grained_access_tokens.md), which can be used
to scope tokens to only the permissions required for the applicable use case. Provision only
the minimum required privileges to user and service tokens to limit the impact of a
compromised token.

### Audit logging and incident management

You are responsible for consuming your application logs. Contact the GitLab Support team to
access specific logs in your tenant's S3 buckets. Underlying infrastructure logs are managed
by Dedicated for Government engineers and monitored by GitLab Security.

### Email

GitLab supports [sending email notifications](../administration/email_from_gitlab.md) and
[configuring application notification emails](../user/profile/notifications.md) for your
instance. DHS Binding Operational Directive 18-01 requires that Domain-based Message
Authentication, Reporting and Conformance (DMARC) is configured for outgoing messages as
spam protection. GitLab Dedicated for Government provides this configuration by default.
You can turn off email notifications if you do not need that functionality.

### GitLab runners

Dedicated for Government customers must build and manage their own
[self-managed runners](../ci/runners/_index.md) outside of their tenant. For configuration
guidance, see [configure runners](../ci/runners/configure_runners.md). Build your runners
using the provided FIPS versions to ensure compliance with FedRAMP requirements.

Runners are an extension of critical infrastructure connected to the FedRAMP boundary.
Misconfigured or compromised runners can introduce supply chain risks to your CI/CD pipeline
and downstream artifacts. Deploy runners in isolated, hardened environments outside of the
Dedicated boundary. Manage access to runner authentication tokens securely, following zero
trust principles, and rotate them regularly. Configure and monitor audit logging for runner
activity.

## Recommendation 2: Secure defaults for administrator accounts

Configuring secure defaults when accounts are first provisioned reduces the risk of
misconfiguration and establishes a strong security baseline from the start.

FedRAMP recommendation: Set all settings to their recommended secure defaults
for top-level administrative accounts and privileged accounts when initially provisioned.

The top-level administrator account is provisioned so you can configure a strong password on
first login. You must [register two-factor authentication (2FA)](../user/profile/account/two_factor_authentication.md)
for the root user in accordance with FedRAMP requirements. GitLab supports a wide range of
factors, including WebAuthn devices that are FIPS-compliant and phishing-resistant.

To align with zero trust security principles, you should:

- Require 2FA for all privileged accounts, not just the root user.
- Implement conditional access policies that verify device posture and user context before
  granting administrative access.
- Enforce session timeouts and require re-authentication for sensitive operations.
- Use FIPS-validated cryptographic modules for all authentication mechanisms.
- Regularly audit and validate that only necessary administrative privileges are granted.

Additional administrators provisioned through your integrated identity provider must meet
organizational controls such as:

- Password length and complexity enforcement
- Failed login lockouts
- PIV/CAC authentication
- Organizationally managed two-factor authentication
- Inactive user lockouts

## Additional resources

GitLab has published a [CIS Benchmark](https://about.gitlab.com/blog/gitlab-introduces-new-cis-benchmark-for-improved-security/)
to guide hardening decisions for administrators. Use it as a starting point to build secure
projects and application resources within your instance.
