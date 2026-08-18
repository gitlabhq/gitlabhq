---
title: Dependency scanning in security configuration profiles
stage: security_risk_management
level: secondary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
documentation_link: "../../../user/application_security/configuration/security_configuration_profiles/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/19952"
categories: [ Security Testing Configuration ]
weight: 20
---

GitLab 18.11 introduced security configuration profiles for SAST and secret detection.
Now, dependency scanning is also available with the **Dependency Scanning - Default** profile.
This profile gives you a unified control surface to apply standardized SCA coverage across all
of your projects without editing a single CI/CD configuration file.

The profile activates two scan triggers:

- **Merge Request Pipelines**: Automatically runs a dependency scanning scan each time new commits are pushed to a branch with an open merge request. Results include only new vulnerabilities introduced by the merge request.
- **Branch Pipelines (default only)**: Runs automatically when changes are merged or pushed to the default branch, providing a complete view of your default branch's dependency posture.
