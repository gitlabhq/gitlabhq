---
title: Audit events for secret push protection fail-open scenarios
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: application_security_testing
documentation_link: "../../../user/application_security/secret_detection/secret_push_protection"
work_item: https://gitlab.com/gitlab-org/gitlab/-/issues/604787
categories: [ Secret Detection ]
---

In earlier versions of GitLab, when secret push protection couldn't complete a scan and allowed a push through unscanned,
GitLab provided no customer-visible audit trail. Security and compliance teams had no way to monitor when secret push
protection silently allowed a push to their repositories.

GitLab 19.3 and later generates [audit events](../../../user/compliance/audit_event_types.md#secret-detection) for all fail-open scenarios,
including ruleset errors, exceeded file and line limits, scan timeouts, and unexpected errors. Teams can now forward these events to external
monitoring and alerting tools to maintain visibility into their security posture.
