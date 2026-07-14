---
title: Scheduled pipeline execution policies (beta)
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/policies/scheduled_pipeline_execution_policies/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/17875"
categories: [ Security Policy Management ]
level: secondary
weight: 50
---

Scheduled pipeline execution policies are now available as a beta feature and no longer
require an experiment flag to enable. You can enforce custom CI/CD jobs on a daily, weekly,
or monthly cadence across your projects, independent of commit activity. Use scheduled
policies to run compliance scripts, security scans, or dependency checks on repositories
that may not have regular code changes.

Scheduled policies now enforce variable precedence consistently with regular pipeline execution
policies. Each security policy project supports up to five scheduled policies, and GitLab
automatically cancels running pipelines when a policy is disabled or deleted. Configure schedules
in YAML or the UI, with time zone support, time window distribution, branch targeting, and snooze
functionality.
