---
title: Dependency scanning auto-remediation (Beta)
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: software_supply_chain_security
documentation_link: "../../../user/application_security/remediate/dependency_scanning_auto_remediation/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/604799
categories: [ Software Composition Analysis ]
level: primary
weight: 50
---

<!-- Category: Software Composition Analysis -->

GitLab 19.2 introduces Dependency scanning auto-remediation in Beta. The feature brings
automated vulnerability remediation directly into your dependency scanning workflow, with
two capabilities:

- Automated dependency version bumps, available on GitLab.com, GitLab Self-Managed, and
  GitLab Dedicated.
- Agentic Breaking Change Resolution, available on GitLab.com, GitLab Self-Managed, and
  GitLab Dedicated, and consumes GitLab Credits.

Automated dependency version bumps automatically opens merge requests to update vulnerable
dependencies to their safe versions. Once turned on, GitLab monitors your projects for
vulnerable dependencies and opens remediation MRs without manual intervention. By default,
updates target patch and minor versions.

Agentic Breaking Change Resolution extends the remediation flow to handle complex updates.
When a merge request that bumps dependency versions has a pipeline fails on a breaking change,
GitLab Duo analyzes the pipeline errors, the dependency's changelog, and how your code uses
the dependency.

GitLab Duo commits fixes to the same MR and re-runs the pipeline until the pipeline passes. When you
enable Agentic Breaking Change Resolution, version bumps extend to include major versions.

Together, the two capabilities form a complete remediation loop: GitLab opens the MR, and
when the update is complex, GitLab Duo resolves it.

For setup instructions, see [Dependency scanning auto-remediation](../../../user/application_security/remediate/dependency_scanning_auto_remediation.md).

Share feedback in the [beta feedback issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/605599).
