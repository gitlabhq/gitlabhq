---
stage: Security
group: Security Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Detect, investigate, and respond to security incidents in GitLab.
title: Security incidents
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

The GitLab Security Operations team wrote these recommendations to help administrators and maintainers of GitLab Self-Managed instances and groups on GitLab.com detect and respond to security incidents that involve GitLab. Use them to supplement the security processes defined by your organization, not to replace them.

Detection and response work together:

1. Detect: Collect audit events and logs, centralize them in a security information and event management (SIEM) system, and deploy detection rules that alert you to suspicious activity.
1. Respond: When a detection fires and you confirm an incident, contain the threat, determine its scope, and remediate the affected accounts, credentials, and settings.

## Detect security incidents

Build detection coverage for security-relevant activity in GitLab. Learn which data sources to collect, how to stream audit events to a SIEM, how to use the open-source TLDR detection framework, and which signals to monitor for common incident scenarios.

For more information, see [security incident detection](detecting_security_incidents.md).

## Respond to security incidents

Contain and remediate common security incidents in GitLab, including exposed credentials, compromised user accounts, CI/CD-related incidents, compromised instances, and misconfigured project or group settings.

For more information, see [security incident response](responding_to_security_incidents.md).

## Related topics

- [Secure GitLab](_index.md)
- [Hardening recommendations](hardening.md)
- [Audit event types](../user/compliance/audit_event_types.md)
