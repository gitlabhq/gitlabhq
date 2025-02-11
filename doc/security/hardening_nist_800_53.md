---
stage: GitLab Dedicated
group: US Public Sector Services
info: All material changes to this page must be approved by the [FedRAMP Compliance team](https://handbook.gitlab.com/handbook/security/security-assurance/security-compliance/fedramp-compliance/#gitlabs-fedramp-initiative). To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments.
title: NIST 800-53 compliance
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

This page provides a reference for GitLab administrators
who want to configure self-managed instances to meet applicable
NIST 800-53 controls. GitLab does not provide specific configuration
guidance because of the variety of requirements an administrator might have.
Before you deploy a GitLab instance that meets the NIST 800-53 security controls,
you should work with a customer solutions architect for technical details.

## Scope

This page follows the structure of the NIST 800-53 control families. Because
the scope of the page is limited primarily to configurations made to GitLab itself, not
all control families apply. Configuration details are intended to be infrastructure agnostic.

GitLab guidance does not constitute a fully compliant system.
Before you handle government data, you should:

- Plan for additional configuration and hardening of your entire technology stack.
- Consider an independent assessment of security configurations.
- Understand the differences in deployments across [supported cloud providers](../install/cloud_providers.md)
  and follow specific guidance where available.

## Compliance features

GitLab offers several [compliance features](../administration/compliance.md) you can use to automate critical controls and workflows in GitLab. Before you make configurations aligned with NIST 800-53, you should enable these foundational features.

## Configuration by control family

### System and Service Acquisition (SA)

GitLab is a [DevSecOps platform](../devsecops.md) that
integrates security throughout the development lifecycle.
At its core, you can use GitLab to address a wide range of controls within the SA control family.

#### System development lifecycle

You can use GitLab to meet the core of this requirement. GitLab provides
a platform where work can be
[organized](../user/project/organize_work_with_projects.md),
[planned, and tracked](../topics/plan_and_track.md).
NIST 800-53 requires that security is incorporated into the development
of the application. You can configure [CI/CD pipelines](../topics/build_your_application.md)
to continuously test code while it ships and simultaneously
enforce security policies. GitLab includes a suite of security tools
that you can incorporate into the development of customer applications,
including but not limited to:

- [Security configuration](../user/application_security/configuration/_index.md)
- [Container Scanning](../user/application_security/container_scanning/_index.md)
- [Dependency Scanning](../user/application_security/dependency_scanning/_index.md)
- [Static Application Security Testing](../user/application_security/sast/_index.md)
- [Infrastructure as Code (IaC) Scanning](../user/application_security/iac_scanning/_index.md)
- [Secret Detection](../user/application_security/secret_detection/_index.md)
- [Dynamic Application Security Testing (DAST)](../user/application_security/dast/_index.md)
- [API fuzzing](../user/application_security/api_fuzzing/_index.md)
- [Coverage-guided fuzz testing](../user/application_security/coverage_fuzzing/_index.md)

Beyond the CI/CD pipeline, GitLab provides [detailed guidance on how to configure releases](../user/project/releases/_index.md).
Releases can be created with a CI/CD pipeline and take a snapshot of any branch of source code in a repository. Instructions for creating releases are included in [Create a Release](../user/project/releases/_index.md#create-a-release).
An important consideration for NIST 800-53 or
FedRAMP compliance is that released code may need to be signed to verify
authenticity of code and satisfy requirements in the System and Information Integrity (SI) control family.

### Access Control (AC) and Identification and Authentication (IA)

Access management in a GitLab deployment is unique to each
customer. GitLab provides a range of documentation that covers
deployments with identity providers and GitLab native authentication
configurations. It is important to consider the organizational
requirements prior to determining how to approach authentication to a
GitLab instance.

#### Identity Providers

Access within GitLab can be managed with the UI or by
integrating with an existing identity provider.
In order to meet FedRAMP requirements, ensure that the
existing identity provider is FedRAMP authorized on the [FedRAMP Marketplace](https://marketplace.fedramp.gov/products). To
meet requirements such as PIV, you should leverage an
identity provider rather than using native authentication in
GitLab Self-Managed.

GitLab provides resources for configuring various
identity providers and protocols, including

- [LDAP](../administration/auth/ldap/_index.md)

- [SAML](../integration/saml.md)

- More information on identity providers can be found in [GitLab Docs](../administration/auth/_index.md).

#### Native GitLab User Authentication Configurations

**Account management and classification** - GitLab empowers
administrators to keep track of users with varying degrees of
sensitivity and access requirements. GitLab supports the concept of
least privilege and role based access by providing options for granular
access. At the project level, the following roles are supported

- Guest

- Reporter

- Developer

- Maintainer

- Owner

Additional details on [project level permissions](../user/permissions.md#project-members-permissions)
can be found in the documentation. GitLab also supports [custom roles](../user/custom_roles.md)
for customers that have unique permission requirements.

GitLab also supports the following user types for unique use cases:

- [Auditor Users](../administration/auditor_users.md) - The auditor role provides read-only access to all groups, projects and other resources except for the **Admin** area and project/group settings. You can use the auditor role when engaging with third-party auditors that require access to certain projects to validate processes.

- [External Users](../administration/external_users.md) -
  External users can be set to provide limited access for users that
  may not be part of the organization. Typically, this can be used to
  satisfy managing access for contractors or other third parties.
  Controls such as IA-4(4) require non-organizational users to be
  identified and managed in accordance with company policy. Setting
  external users can reduce risk to an organization by limiting access
  to projects by default and assisting administrators in identifying
  which users are not employed by the organization.

- [Service Accounts](../user/profile/service_accounts.md#administrators-in-gitlab-self-managed) -
  Service accounts may be added to accommodate automated tasks.
  Service accounts do not use a seat under the license.

**Admin** area - In the **Admin** area, administrators can [export permissions](../administration/admin_area.md#user-permission-export),
[review user identities](../administration/admin_area.md#user-identities), [administer groups](../administration/admin_area.md#administering-groups),
and much more. Functions that can be used to meet FedRAMP / NIST 800-53
requirements:

- [Reset user password](reset_user_password.md) when suspected of compromise.

- [Unlock users](unlock_user.md).
  By default, GitLab locks users after 10 failed sign-in attempts.
  Users remain locked for 10 minutes or until an administrator unlocks
  the user. In GitLab 16.5 and later, administrators can [use the API](../api/settings.md#available-settings)
  to configure max login attempts and time period for remaining locked
  out. Per guidance in AC-7, FedRAMP defers to NIST 800-63B for
  defining parameters for account lockouts, which the default setting
  satisfies.

- Review [abuse reports](../administration/review_abuse_reports.md)
  or [spam logs](../administration/review_spam_logs.md).
  FedRAMP requires organizations to monitor accounts for atypical use
  (AC-2(12)). GitLab empowers users to flag abuse in abuse reports,
  where administrators can remove access pending investigation. Spam
  logs are consolidated in the **Spam logs** section of the **Admin** area.
  Administrators can remove, block, or trust users flagged in that
  area.

- [Set password storage parameters](password_storage.md).
  Stored secrets must satisfy FIPS 140-2 or 140-3 as outlined in
  SC-13. PBKDF2+SHA512 is supported with FIPS compliant ciphers when
  FIPS mode is enabled.

- [Credentials inventory](../administration/credentials_inventory.md)
  enables administrators to review all secrets used in a GitLab
  self-managed instance in one place. A consolidated view of
  credentials, tokens, and keys may assist with satisfying
  requirements such as reviewing passwords or rotating credentials.

- [Set customer password length limits](password_length_limits.md).
  FedRAMP defers to NIST 800-63B in IA-5 for establishing password
  length requirements. GitLab supports 8-128 character passwords, with
  8 characters set as the default. GitLab provides [instructions for updating the minimum password length](password_length_limits.md#modify-minimum-password-length)
  with the GitLab UI, which organizations interested
  in enforcing longer passwords can use. Additionally, self-managed customers
  may [configure complexity requirements](../administration/settings/sign_up_restrictions.md#password-complexity-requirements)
  through the **Admin** area UI.

- [Default session durations](../administration/settings/account_and_limit_settings.md#customize-the-default-session-duration) -
  FedRAMP establishes that users that have been inactive for a set
  time period should be logged out. FedRAMP does not specify the time
  period, however, clarifies that for privileged users they should be
  logged out at the end of the standard work period. Administrators
  can establish [default session durations](../administration/settings/account_and_limit_settings.md#customize-the-default-session-duration).

- [Provisioning New Users](../user/profile/account/create_accounts.md) -
  Administrators can create new users for their GitLab account with the
  **Admin** area UI. In compliance with IA-5, GitLab requires new users to
  change their passwords on first login.

- Deprovisioning Users - Administrators are able to [remove users with the **Admin** area UI](../user/profile/account/delete_account.md#delete-users-and-user-contributions).
  An alternative to deleting users is to [block a user](../administration/moderate_users.md#block-a-user)
  and remove all access. Blocking a user maintains their data in
  repositories while removing all access. Blocked users do not impact
  seat counts.

- Deactivate Users - Inactive users that have been identified during account reviews [may be temporarily deactivated](../administration/moderate_users.md#deactivate-a-user). Deactivation is similar to blocking, but there are a few important differences. Deactivating a user does not prohibit the user from signing into the GitLab UI. A deactivated user can become active again by signing in. A deactivated user:
  - Cannot access repositories or the API.

  - Cannot use slash commands. For more information, see slash commands.

  - Does not occupy a seat.

#### Additional Identification Methods

**Two-factor authentication** - [GitLab supports the following second factors](../user/profile/account/two_factor_authentication.md):

- One-time password authenticators

- WebAuthn devices

[Instructions for enabling two-factor authentication](../user/profile/account/two_factor_authentication.md#enable-two-factor-authentication)
are provided in the documentation. Customers pursuing FedRAMP must consider
two-factor providers that are FedRAMP authorized and support FIPS
requirements. FedRAMP authorized providers can be found on the [FedRAMP Marketplace](https://marketplace.fedramp.gov/products).
When selecting a second factor, it is important to note that NIST and
FedRAMP are now indicating that phishing resistant authentication, such
as WebAuthn, must be used (IA-2).

**SSH keys**

- GitLab [provides instructions](../user/ssh.md) on how to configure SSH keys to authenticate and communicate with Git. [Commits can be signed](../user/project/repository/signed_commits/ssh.md), providing additional verification for anyone with a public key.

- Keys should be configured to meet applicable strength and complexity requirements, such as using FIPS 140-2 and FIPS 140-3 validated ciphers . Administrators can [restrict minimum key technologies and key lengths](ssh_keys_restrictions.md). Additionally, administrators can [block or ban compromised keys](ssh_keys_restrictions.md#block-banned-or-compromised-keys).

**Personal access tokens**

Personal access tokens for user access are disabled by default in FIPS
enabled instances.

#### Other Access Control Family Concepts

**System Use Notifications**

Federal requirements often outline the need for a banner at login. This
can be configured through an identity provider and through the [GitLab banner functionality](../administration/broadcast_messages.md).

**External Connections**

It is important to document all external connections and ensure that
they meet compliance requirements. For example, setting up an API
integration with a third party may violate data handling requirements,
depending on how that third party secures customer data. It is important
to review all external connections and understand their security impacts
prior to enabling them. For customers pursuing FedRAMP or similar
certifications, connecting to other non-FedRAMP authorized services or
services of a lower data impact level may violate the authorization
boundary.

**Personal Identity Verification (PIV)**

Personal Identification Verification cards may be a requirement for
organizations meeting federal requirements. In order to meet PIV
requirements, GitLab requires customers to connect PIV-enabled identity
solutions with SAML. A link to SAML documentation is provided earlier in
this guide.

### Audit and Accountability (AU)

NIST 800-53 requires organizations to monitor for security relevant
events, analyze those events, generate alerts, and investigate alerts in
accordance with the criticality of the alerts. GitLab provides a wide
array of security events for monitoring that can be routed to a Security
Information and Event Management (SIEM) solution.

#### Event Types

GitLab outlines the [configurable audit event log types](../administration/audit_event_streaming/_index.md),
which can be streamed and/or saved to a database. Administrators are
able to configure the events that they'd like captured for their GitLab
instance.

**Log System**

GitLab includes an advanced log system where everything can be logged.
GitLab offers [guidance on log system](../administration/logs/_index.md#importerlog)
log types, which include a wide range of outputs. Review the linked
guidance for further details.

Streaming Events

GitLab administrators can stream audit events to a SIEM or other storage
location using the [event streaming functionality](../user/compliance/audit_event_streaming.md).
Administrators can configure multiple destinations and set event
headers. GitLab [provides examples](../user/compliance/audit_event_schema.md)
for event streaming which outline headers, payloads for HTTP and HTTPS
events, and much more.

It is important for administrators to review the FedRAMP or NIST 800-53
AU-2 requirements and implement audit events that map to the required
audit event type. AU-2 identifies the following event buckets:

- Successful and unsuccessful account logon events

- Account management events

- Object access

- Policy change

- Privilege functions

- Process tracking

- System events

- For Web applications:

  - All administrator activity

  - Authentication checks

  - Authorization checks

  - Data deletions

  - Data access

  - Data changes

  - Permission changes

Administrators should consider both the required event types and any
additional organizational requirements when enabling events in GitLab.

**Metrics**

Outside of security events, administrators may also want visibility into
the performance of their application to support uptime. GitLab provides
a [robust set of documentation around metrics](../administration/monitoring/_index.md)
that are supported in a GitLab instance.

**Storage**

Customers are responsible for ensuring that logs are stored in a
long-term storage solution that meets compliance requirements. FedRAMP,
for example, requires logs to be stored for 1 year. Customer
organizations may also need to meet National Archives and Records
Administration requirements, depending on the impact of the collected
data. It is important to review the impact of records collected and
understand the applicable compliance requirements.

### Incident Response (IR)

Once audit events have been configured, those events must be monitored.
GitLab provides a centralized management interface for compiling system
alerts from a SIEM or other security tooling, triaging alerts and
incidents, and informing stakeholders. The [incident management documentation](../operations/incident_management/_index.md)
outlines how GitLab can be used to run the aforementioned activities
in a security incident response organization.

**Incident Response Lifecycle**

GitLab can manage the entirety of the incident response lifecycle for an
organization. Review the following resources, which may help meet
incident response requirements:

- [Alerts](../operations/incident_management/alerts.md)

- [Incidents](../operations/incident_management/incidents.md)

- [On-call Schedules](../operations/incident_management/oncall_schedules.md)

- [Status page](../operations/incident_management/status_page.md)

### Configuration Management (CM)

**Change Control**

GitLab, at its core, can satisfy configuration management requirements
related to change control. Issues and merge requests are the primary
methods for supporting changes.

Issues are a flexible platform for capturing metadata and approvals
prior to implementing changes. Consider reviewing GitLab documentation
on [planning and tracking work](../topics/plan_and_track.md)
to gain a full understanding of how GitLab features can be used to
satisfy configuration management controls.

Merge requests offer a method for standardizing changes from a source
branch to a target branch. In the context of NIST 800-53, it is
important to consider how approvals should be collected prior to merging
code and who has the ability to merge code within the organization.
GitLab provides guidance on the [various settings available for approvals in merge requests](../user/project/merge_requests/approvals/_index.md).
Consider assigning approval and merge privileges only to appropriate
roles after the necessary reviews have been completed. Additional merge
settings to consider:

- Remove all approvals when a commit is added - Ensures that approvals
  are not carried over when new commits are made to a merge request.

- Restrict individuals who can dismiss code change reviews.

- Assign [code owners](../user/project/codeowners/_index.md#codeowners-file)
  to be notified when sensitive code or configurations are changed through
  merge requests.

- [Ensure all open comments are resolved before allowing code change merging](../user/project/merge_requests/_index.md#prevent-merge-unless-all-threads-are-resolved).

- [Configure push rules](../user/project/repository/push_rules.md) -
  Push rules can be configured to meet requirements such as reviewing
  signed code, verifying users, and more.

**Testing and Validation of Changes**

[CI/CD pipelines](../topics/build_your_application.md)
are a critical component of testing and validating changes. It is the
responsibility of the customer to implement sufficient testing and
validation pipelines for specific use cases. When selecting services,
consider where that pipeline will run. Connecting to external services
may violate an established authorization boundary where federal data is
permitted to be stored and processed. GitLab provides runner container
images configured to run on FIPS-enabled systems. GitLab provides
hardening guidance for pipelines, including how to [configure protected branches](../user/project/repository/branches/protected.md)
and [implement pipeline security](../ci/pipelines/_index.md#pipeline-security-on-protected-branches).
Additionally, customers may want to consider assigning [required checks](../user/project/merge_requests/status_checks.md)
before merging code to ensure that all checks have passed prior to
updating the code.

**Component Inventory**

NIST 800-53 requires cloud services providers to maintain component
inventories. GitLab cannot directly track underlying hardware, however,
it can generate software inventories via container and dependency
scanning. GitLab outlines the [dependencies that container scanning and dependency scanning can detect](../user/application_security/comparison_dependency_and_container_scanning.md).
GitLab offers additional documentation around generating dependency
lists, which can be used in [software component inventories](../user/application_security/dependency_list/_index.md).
Software Bill of Materials support is covered further down in this
document, under Supply Chain Risk Management.

**Container Registry**

GitLab provides an integrated container registry to store container
images for GitLab projects, which can be used as an authoritative
repository for deploying containers in a highly virtualized and scalable
environment. [Container registry administration guidance](../administration/packages/container_registry.md)
is available for review.

### Contingency Planning (CP)

GitLab provides guidance and services that can help meet the core
contingency planning requirements. It is important to review the
included documentation and plan accordingly to meet organizational
requirements for contingency planning activities. Contingency planning
is unique to each organization so it is important to consider
organizational needs prior to establishing a contingency plan.

**Selecting a GitLab Architecture**

GitLab provides extensive documentation on the architectures supported
in a self-managed instance. GitLab supports the following cloud service
providers:

- [Azure](../install/azure/_index.md)

- [Google Cloud Platform](../install/google_cloud_platform/_index.md)

- [Amazon Web Services](../install/aws/_index.md)

GitLab provides a [decision tree for assisting customers with selecting reference architectures and availability models](../administration/reference_architectures/_index.md#decision-tree).
Most cloud service providers provide resiliency in a region for
managed services. When selecting an architecture, it is important to
consider the organization's tolerance for downtime and the criticality
of data. GitLab Geo can be considered for additional replication and
failover capabilities.

**Identify Critical Assets**

NIST 800-53 requires the identification of critical assets to ensure
their prioritized restoration during an outage. Critical assets to
consider include Gitaly nodes and PostgreSQL databases. Customers should
identify additional assets that need backups or replication as
appropriate.

**Backups**

GitLab Docs outlines backup strategies for critical components,
including:

- [PostgreSQL databases](../administration/backup_restore/backup_gitlab.md#postgresql-databases)

- [Git repositories](../administration/backup_restore/backup_gitlab.md#git-repositories)

- [Blobs](../administration/backup_restore/backup_gitlab.md#blobs)

- [Container Registry](../administration/backup_restore/backup_gitlab.md#container-registry)

- [Redis](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/#backing-up-redis-data)

- [Configuration Files](../administration/backup_restore/backup_gitlab.md#storing-configuration-files)

- [Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshot-restore.html)

GitLab Geo

GitLab Geo is likely to be a critical component of any implementation
pursuing compliance with NIST 800-53. It is important to review [the available documentation](../administration/geo/_index.md)
to ensure that Geo is configured appropriately for each use case.

Implementing Geo provides the following benefits:

- Reduce from minutes to seconds the time taken for distributed
  developers to clone and fetch large repositories and projects.

- Enable developers to contribute ideas and work in parallel, across
  regions.

- Balance the read-only load between primary and secondary sites.

- Can be used for cloning and fetching projects, in addition to
  reading any data available in the GitLab web interface (see
  limitations).

- Overcomes slow connections between distant offices, saving time by
  improving speed for distributed teams.

- Helps reduce the loading time for automated tasks, custom
  integrations, and internal workflows.

- Can quickly fail over to a secondary site in a disaster recovery
  scenario.

- Allows planned failover to a secondary site.

Geo provides the following core features:

- Read-only secondary sites: Maintain one primary GitLab site while
  still enabling read-only secondary sites for distributed teams.

- Authentication system hooks: Secondary sites receive all
  authentication data (like user accounts and logins) from the primary
  instance.

- An intuitive UI: Secondary sites use the same web interface as the
  primary site. In addition, there are visual notifications that block
  write operations and make it clear that a user is in a secondary
  site.

Additional Geo Resources:

- [Setting up Geo](../administration/geo/setup/_index.md)

- [Requirements for running Geo](../administration/geo/_index.md#requirements-for-running-geo)

- [Geo Limitations](../administration/geo/_index.md)

- [Geo Disaster Recovery Steps](../administration/geo/disaster_recovery/_index.md)

**PostgreSQL**

GitLab provides [guidance on how to configure PostgreSQL clusters with replication and failover](../administration/postgresql/replication_and_failover.md).
Depending on the criticality of data and maximum tolerable downtime for
the GitLab instance, consider configuring PostgreSQL with replication
and failover enabled.

**Gitaly**

When configuring Gitaly, consider the tradeoffs between availability,
recoverability, and resilience. GitLab provides extensive documentation
on [Gitaly capabilities](../administration/gitaly/gitaly_geo_capabilities.md)
that should assist with determining the correct configuration to meet
NIST 800-53 requirements.

### Planning (PL)

The planning control family includes maintenance of policies, procedures
and other controlled documents. Consider leveraging GitLab to manage the
lifecycle of controlled documents. For example, controlled documents can
be stored in
[Markdown](../user/markdown.md)
as a version-controlled state. Any changes to documents must be made
through merge requests, which enforce an organization's approval rules.
Merge requests provide a clear history of changes made to a controlled
document, which you can use during an audit to demonstrate annual
reviews and approvals by appropriate personnel, such as document owners.

### Risk Assessment and System and Information Integrity (RA)

#### Scanning

NIST 800-53 requires continuous monitoring for vulnerabilities and flaw
remediation. In addition to infrastructure scanning, compliance
frameworks like FedRAMP have scoped in containers and DAST scans into
monthly reporting requirements. GitLab provides security
[tooling that can support container scanning](../user/application_security/container_scanning/_index.md),
including [Trivy](https://github.com/aquasecurity/trivy)
and [Grype](https://github.com/anchore/grype) scanners.
Additionally, GitLab provides [dependency scanning functionality](../user/application_security/dependency_scanning/_index.md).
Dynamic Application Security Testing (DAST) in GitLab can be used to
satisfy web application scanning requirements. [GitLab DAST](../user/application_security/dast/_index.md)
can be configured to run in a pipeline and produce vulnerability reports
for running web applications.

Additional security features that may be used to secure and manage
application code include:

- [Static Application Security Testing (SAST)](../user/application_security/sast/_index.md)

- [Secret Detection](../user/application_security/secret_detection/_index.md)

- [API Security](../user/application_security/api_security/_index.md)

#### Patch Management

GitLab documents its [Release and Maintenance Policy](../policy/maintenance.md)
in the documentation. Prior to upgrading a GitLab instance, please review the
available guidance, which can assist with [planning an upgrade](../update/plan_your_upgrade.md),
[upgrading without downtime](../update/zero_downtime.md),
and other [upgrade paths](../update/upgrade_paths.md).

[Security dashboards](../user/application_security/security_dashboard/_index.md)
can be configured to track vulnerability data over time, which you can use to identify
trends in vulnerability management programs.

### Supply Chain Risk Management (SR)

#### Software Bill of Materials

GitLab dependency and container scanners support the generation of
SBOMs. Enabling SBOM reports in container and dependency scanning
can empower customer organizations to understand their software supply
chain and the inherent risks associated with software components. GitLab
scanners [support CycloneDX formatted reports](../ci/yaml/artifacts_reports.md#artifactsreportsdotenv).

### System and Communication Protection (SC)

#### FIPS Compliance

Compliance programs based on NIST 800-53, such as FedRAMP, require FIPS
compliance for all applicable cryptographic modules. GitLab has released
FIPS versions of its container images and provides guidance on
[how to configure GitLab to meet FIPS compliance standards](../development/fips_gitlab.md).
It is important to note that
[certain features are not available or supported in FIPS mode](../development/fips_gitlab.md#unsupported-features-in-fips-mode).

While GitLab provides FIPS-compliant images, it is the responsibility of
the customer to configure underlying infrastructure and evaluate the
environment to confirm FIPS-validated ciphers are enforced.

### System and Information Integrity (SI)

#### Security Alerts, Advisories, and Directives

GitLab maintains an [advisory database](../user/application_security/gitlab_advisory_database/_index.md)
for tracking security vulnerabilities related to software and
dependencies. GitLab is a CVE Numbering Authority (CNA). Follow this
page for generating [CVE ID Requests](../user/application_security/cve_id_request.md).

#### Email

GitLab supports the [sending of email notifications](../administration/email_from_gitlab.md#sending-emails-to-users-from-gitlab)
to users from the GitLab application instance. DHS BOD 18-01 guidance
indicates that Domain-based Message Authentication, Reporting &
Conformance (DMARC) must be configured for outgoing messages as spam
protection. GitLab provides [configuration guidance for SMTP](https://docs.gitlab.com/omnibus/settings/smtp.html)
across a wide range of email providers, which may be used to help meet
this requirement.

### Other Services and Concepts

#### Runners

Runners are required for a wide variety of tasks and tools in any GitLab
deployment. To maintain data boundary requirements, customers may need
to deploy [self-managed runners](https://docs.gitlab.com/runner/)
in their authorization boundary. GitLab provides detailed
information on [configuring runners](../ci/runners/configure_runners.md),
which includes concepts such as:

- Maximum job timeouts

- Protecting Sensitive Information

- Configuring Long Polling

- Authentication Token Security and Token Rotation

- Preventing Revealing Sensitive Information

- Runner Variables

#### Leveraging APIs

GitLab provides a robust set of APIs to support the application,
including [REST](../api/rest/_index.md) and
[GraphQL](../api/graphql/_index.md) APIs.
Securing APIs starts with the proper configuration of authentication for
users and jobs calling the API endpoints. GitLab recommends configuring
access tokens (personal access tokens not supported by FIPS) and OAuth
2.0 tokens to control access.

#### Extensions

[Extensions](../editor_extensions/_index.md)
may meet NIST 800-53 requirements depending on which integrations are
established. Editor and IDE extensions, for example, may be permissible
whereas integrations with third parties may violate authorization
boundary requirements. It is the customer's responsibility to validate
all extensions to understand where data is being sent outside of the
customer's authorization boundary.

### Additional Resources

GitLab provides a [hardening guide](hardening.md)
for self-managed customers that covers topics such as:

- [Application hardening recommendations](hardening_application_recommendations.md)

- [CI/CD Hardening Recommendation](hardening_cicd_recommendations.md)

- [Configuration Recommendations](hardening_configuration_recommendations.md)

- [Operating System Recommendations](hardening_operating_system_recommendations.md)

GitLab CIS Benchmark Guide - GitLab has published a [CIS Benchmark](https://about.gitlab.com/blog/2024/04/17/gitlab-introduces-new-cis-benchmark-for-improved-security/)
to guide hardening decisions in the application. This may be used in
concert with this guide to harden the environment in accordance with NIST 800-53
controls. Not all suggestions in the CIS Benchmark directly align with
NIST 800-53 controls, but serve as best-practices for maintaining a
GitLab instance.
