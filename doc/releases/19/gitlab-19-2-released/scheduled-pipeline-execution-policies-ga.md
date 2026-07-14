---
title: Scheduled pipeline execution policies are GA
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/policies/scheduled_pipeline_execution_policies/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/17875"
categories: [ Security Policy Management ]
level: primary
weight: 10
---

Scheduled pipeline execution policies are now generally available. Define a schedule once in a
security policy project and enforce it across every project in scope, without editing each
project's `.gitlab-ci.yml`. If requirements change, update the policy in one place instead of
coordinating changes across many CI/CD configuration files.

Use scheduled policies to run compliance scripts, security scans, or other custom CI/CD jobs on a
daily, weekly, or monthly cadence, independent of commit activity. This is useful for repositories
without regular code changes, such as running dependency scans to detect newly discovered
vulnerabilities. Each policy runs as a separate pipeline, with time zone support, time window
distribution, and branch targeting.
