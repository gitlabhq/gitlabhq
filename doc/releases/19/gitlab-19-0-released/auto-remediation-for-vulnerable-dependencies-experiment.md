---
title: Auto remediation for vulnerable dependencies (Experiment)
stage: software_supply_chain_security
level: secondary
tier: [ Ultimate ]
offering: [ gitlab_com ]
documentation_link: "../../../user/application_security/remediate/auto_remediation/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/17403"
categories: [ Software Composition Analysis ]
weight: 10
---

Auto remediation for dependencies is now available as an experiment in GitLab 19.0. When dependency
scanning detects a vulnerable Ruby dependency with a known fix, GitLab automatically
opens a merge request to update it to a safe version without human input. Only Ruby projects are supported
in the experiment.

After each pipeline, GitLab identifies the highest-severity vulnerability with an
available patch or minor version upgrade. GitLab generates the manifest file change and
opens a merge request through a service account. The merge request then goes through
your project's standard review and approval workflow.

During the experiment, up to three auto-remediation merge requests can be open per
project at a time.

To share feedback or request to try out the experiment make a comment on [epic 600511](https://gitlab.com/gitlab-org/gitlab/-/work_items/600511).
To enable the experiment on your project, a GitLab team member must enable the `dependency_management_auto_remediation` feature flag for your project.
