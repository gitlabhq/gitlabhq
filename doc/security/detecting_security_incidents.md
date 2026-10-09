---
stage: Security
group: Security Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Security incident detection
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

The sooner you detect a potential security incident, the more you can limit its impact.

The GitLab Security Operations team wrote these recommendations for administrators and maintainers of GitLab Self-Managed instances and groups on GitLab.com. Use them to build detection coverage for security-relevant activity in GitLab, and to recognize the signals that indicate a potential security incident. They supplement the detection and monitoring processes defined by your organization, but don't replace them.

When you confirm an incident, follow [responding to security incidents](responding_to_security_incidents.md) to contain and remediate it.

> [!warning]
> Use these suggestions and recommendations at your own risk. Detection coverage depends on your configuration, subscription tier, and the logging and monitoring tooling in your environment.

## Build a detection capability

Effective detection combines reliable data sources, a central place to analyze them, and tuned rules that turn raw activity into actionable alerts.

### Detection data sources

GitLab produces several sources of security-relevant data that you can use to detect suspicious activity:

| Data source | Availability | What it shows |
|-------------|--------------|---------------|
| [Audit events](../administration/compliance/audit_event_reports.md) | Premium, Ultimate | Authentication, permission changes, and changes to projects, groups, and settings. The primary source for detecting security incidents in GitLab. For the full list, see [audit event types](../user/compliance/audit_event_types.md). |
| [Sign-in audit events](../user/compliance/audit_events.md#sign-in-audit-events) | All tiers | Successful sign-ins for a user, in the **Authentication log** of the user profile. |
| [System logs](../administration/logs/_index.md) | All tiers, GitLab Self-Managed only | Application, API, authentication, and Workhorse logs. Use the [correlation ID](../administration/logs/tracing_correlation_id.md) to trace a single request across multiple logs. |
| [CI/CD job logs](../ci/jobs/job_logs.md) | All tiers | Exposed secrets, unexpected commands, or pipeline activity started by an attacker. |
| [Credentials inventory](../administration/credentials_inventory.md) | Ultimate | Personal, group, and project access tokens, SSH keys, and GPG keys that exist in your instance or top-level group. |
| [Secret push protection](../user/application_security/secret_detection/secret_push_protection/_index.md) and [secret detection](../user/application_security/secret_detection/_index.md) | Secret push protection: Ultimate. Pipeline secret detection: All tiers. | Secrets that users attempt to push, or that are committed to a repository. |

For more information about what each source contains and how to collect it on each offering and subscription tier, see [security telemetry](security_telemetry.md).

To detect suspicious authentication, such as sign-ins from unexpected locations or changes to two-factor authentication, review [system access audit events](../user/compliance/audit_event_types.md#system-access).

### Centralize and stream events to a SIEM

To detect incidents in near real time and retain events for investigation, centralize your data in a security information and event management (SIEM) system or another log analysis platform:

- Stream audit events to an external destination.
  - GitLab Self-Managed and GitLab Dedicated: [Audit event streaming for instances](../administration/compliance/audit_event_streaming.md) 
  - GitLab.com: [Audit event streaming for top-level groups](../user/compliance/audit_event_streaming.md)
- If you don't stream events, you can collect them on a schedule with the [Audit events API](../api/audit_events.md).
- Route logs and events to an independent, write-once (immutable) datastore so an attacker cannot alter or delete them.
- Define a retention period that meets your investigation and compliance requirements before you need the data.

### Use the GitLab detection rules

The GitLab Security Operations team maintains [TLDR](https://gitlab.com/gitlab-security-oss/tldr) (Threat, Logs, Detection, Respond), an open-source detection framework for GitLab environments.

Each TLDR detection includes a variety of information:

- Threat details: A description of the threat, and its technical and business impact.
- Logs: The log sources the detection requires, with sample events.
- Detection: A rule in the general [Sigma](https://github.com/SigmaHQ/sigma) format, and a raw log query for environments without a SIEM.
- Atomic test: Steps to reproduce the activity, so you can confirm the detection fires.
- Response: Guidance on how to handle a true positive.

The detections are grouped into two types:

- Threat detections: Suspicious or malicious activity recorded in audit events, such as disabled two-factor authentication, new administrator accounts, new deploy keys or project access tokens, and changes to merge request approval or protected branch settings.

- Vulnerability detections: Attempts to exploit known vulnerabilities in GitLab Self-Managed, recorded in application logs.

To use these detections:

1. Ingest the log sources listed in each detection into your SIEM.
1. Convert the Sigma rules to the query language of your SIEM. Use the official [Sigma CLI](https://github.com/SigmaHQ/sigma-cli) or the web-based [sigconverter.io](https://sigconverter.io/).
1. Deploy the converted rules in a monitoring-only mode first, and review the alert volume.
1. Tune the rules to fit your environment before you route alerts to on-call responders.

### Map coverage and tune detections

After you deploy detections, review them regularly so they stay accurate and cover the threats that matter to your organization:

- Map your detections to a framework such as [MITRE ATT&CK](https://attack.mitre.org/) to understand which adversary techniques you can detect and where you have gaps.
- Baseline normal activity in your environment so that alerts focus on meaningful deviations.
- Tune noisy rules so that high-severity alerts remain trustworthy.
- Test that each detection fires as expected, and document the expected behavior for each rule. Each TLDR detection includes an atomic test that you can use for this.

## What to detect, by scenario

Most of the following scenarios match the [common security incident scenarios](responding_to_security_incidents.md#common-security-incident-scenarios) for incident response. For each scenario, monitor the listed signals. When a detection fires and you confirm an incident, follow the linked response steps.

The following table maps each scenario to example MITRE ATT&CK techniques. Use these mappings as a starting point, and adjust them to your own threat model.

| Scenario | Key signals | Example MITRE ATT&CK techniques |
|----------|-------------|---------------------------------|
| [Credential exposure and token abuse](#credential-exposure-and-token-abuse) | New tokens, keys, or users, and CI/CD variable changes | T1552 Unsecured Credentials, T1078 Valid Accounts, T1136 Create Account |
| [Compromised user account](#compromised-user-account) | Unusual sign-ins, two-factor authentication changes, new OAuth applications | T1078 Valid Accounts, T1110 Brute Force, T1098 Account Manipulation, T1556 Modify Authentication Process |
| [CI/CD abuse](#cicd-abuse) | Pipeline configuration, variable, or runner changes | T1195.002 Compromise Software Supply Chain, T1552 Unsecured Credentials |
| [Compromised instance](#compromised-instance) | New administrators, root user activity, host indicators | T1078 Valid Accounts, T1098 Account Manipulation, T1136 Create Account |
| [Misconfigured project or group settings](#misconfigured-project-or-group-settings) | Visibility, approval, and protected branch changes | T1685 Disable or Modify Tools, T1485 Data Destruction |
| [Data exfiltration](#data-exfiltration) | Bulk clones, project exports, new deploy keys or tokens | T1213.003 Code Repositories, T1567 Exfiltration Over Web Service |
| [Abuse and resource misuse](#abuse-and-resource-misuse) | Compute spikes, bursts of new accounts, excessive Git operations | T1496 Resource Hijacking, T1136 Create Account |

### Credential exposure and token abuse

Watch for activity that suggests a token, key, or other credential has been exposed or misused:

- Creation of personal, project, or group access tokens, especially by unexpected users.
- Creation of SSH or GPG keys.
- Creation of new user accounts, which adversaries might use to maintain persistence.
- Changes to [CI/CD variables](../ci/variables/_index.md) or other configuration that stores secrets. Focus on [continuous integration audit events](../user/compliance/audit_event_types.md#continuous-integration).
- Pipelines run by an unexpected user. Review the [job logs](../administration/cicd/job_logs.md) for details.

To respond, see [credential exposure to public internet](responding_to_security_incidents.md#credential-exposure-to-public-internet).

### Compromised user account

Watch for signals that an account is being used by someone other than its owner:

- Suspicious sign-in events, such as those from unexpected IP addresses, locations, or devices.
- Creation or deletion of personal, project, or group access tokens.
- Creation or deletion of SSH or GPG keys.
- Changes to two-factor authentication settings.
- Changes to email addresses or notification settings.
- Addition or modification of authorized OAuth applications.
- Changes to connected SAML identity providers.

To respond, see [suspected compromised user account](responding_to_security_incidents.md#suspected-compromised-user-account).

### CI/CD abuse

Watch for changes that could expose secrets or let an attacker run code in your pipelines:

- Modifications to CI/CD configuration files or pipeline definitions.
- Changes to CI/CD variables, including [masking](../ci/variables/_index.md#mask-a-cicd-variable) and protection settings.
- Changes that make pipelines or job artifacts publicly accessible.
- Registration of new runners or changes to existing runners.
- Unexpected use of the [CI/CD job token](../ci/jobs/ci_job_token.md#gitlab-cicd-job-token-security).

To respond, see [CI/CD-related security incidents](responding_to_security_incidents.md#cicd-related-security-incidents).

### Compromised instance

For GitLab Self-Managed, watch for instance-level and host-level signals:

- System access audit events that show changes to system settings, user permissions, or sign-in events.
- Creation of new administrator accounts, or activity from the administrative root user.
- Host-level indicators such as unrecognized background processes, unexpected open ports, or unusual network traffic.

To respond, see [suspected compromised instance](responding_to_security_incidents.md#suspected-compromised-instance).

### Misconfigured project or group settings

Watch for changes that can expose data or weaken access controls:

- Changes to project or group visibility.
- Modifications to merge request approval settings.
- Project deletions.
- Addition of suspicious webhooks or [server hooks](../administration/server_hooks.md).
- Changes to protected branch settings.

Filter audit events by the `target_type` field to narrow your search, and review [compliance management](../user/compliance/audit_event_types.md#compliance-management) and [groups and projects](../user/compliance/audit_event_types.md#groups-and-projects) audit events.

To respond, see [misconfigured project or group settings](responding_to_security_incidents.md#misconfigured-project-or-group-settings).

### Data exfiltration

Watch for signs that source code or other data is being copied out of GitLab, often after an attacker gains access through a compromised account or token:

- Many repository downloads or clones by a single user or token in a short period.
- Project or group exports, and downloads of export files, especially by users who don't usually perform them.
- New deploy keys or deploy tokens, which give long-lived access to repositories.
- Job artifact downloads by unexpected users.
- Changes that make private projects or groups public.
- Personal access tokens used from a previously unseen IP address.

To respond, revoke the credentials involved by following [credential exposure to public internet](responding_to_security_incidents.md#credential-exposure-to-public-internet), and follow the incident response process defined by your organization.

### Abuse and resource misuse

Watch for automated abuse and unexpected consumption of resources, such as cryptocurrency mining in CI/CD:

- Spikes in pipeline activity, compute minutes, or new runner registrations.
- Bursts of new account creation.
- Excessive Git operations. On Ultimate, you can configure the [Git abuse rate limit](../user/group/reporting/git_abuse_rate_limit.md) to automatically mitigate some of these patterns.

To respond, follow the incident response process defined by your organization, and review the [hardening recommendations](hardening.md).

## When a detection fires

When a detection triggers an alert, triage it to confirm whether a security incident is in progress:

1. Preserve evidence. Save relevant logs and audit events to a write-once location for later investigation.
1. Determine the scope, such as the affected users, projects, groups, tokens, or hosts.
1. Follow the response steps linked from the matching scenario to contain and remediate the incident.
1. Follow the incident response process defined by your organization.

## Engaging GitLab for assistance

Before you ask GitLab for help, search the [GitLab documentation](https://docs.gitlab.com). Contact GitLab Support after you complete a preliminary investigation and still have questions or need assistance. Eligibility for assistance from GitLab Support is [determined by your license](https://support.gitlab.com/hc/en-us/articles/11626483177756-GitLab-Support#gitlab-support-service-levels).

## Related topics

- [Security incidents](security_incidents.md)
- [Security telemetry](security_telemetry.md)
- [Secure GitLab](_index.md)
- [Audit event types](../user/compliance/audit_event_types.md)
