---
title: Hosted runners for GitLab Dedicated are generally available
tier: [ Ultimate ]
offering: [ gitlab_dedicated ]
stage: production_engineering
documentation_link: "../../../administration/dedicated/hosted_runners"
work_item: https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/transistor/-/merge_requests/834
categories: [ GitLab Hosted Runners ]
level: secondary
weight: 50
---

Hosted runners for GitLab Dedicated are now generally available. GitLab provisions, patches, and
scales runners for you, within the same security and compliance boundary as your GitLab Dedicated
instance.

Key capabilities include:

- AWS EC2 instances in the same region as your GitLab Dedicated instance, running in single-tenant, ephemeral VMs destroyed after each job
- Secure outbound PrivateLink connection to your GitLab instance
- Linux x86-64 and Arm64 runners in five sizes, from small to 2X-large
- 99.9% uptime SLA, calculated separately from your GitLab Dedicated instance SLA, to ensure your workflows remain stable, resilient, and online

You create and manage hosted runners yourself in Switchboard, and pay only for what you use, with
usage tracked on the GitLab Credits dashboard. To get started, contact your customer success
manager or account representative.
