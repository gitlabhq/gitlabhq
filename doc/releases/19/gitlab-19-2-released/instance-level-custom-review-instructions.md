---
title: Instance-level custom review instructions
offering: [ self_managed, gitlab_dedicated ]
tier: [ Premium, Ultimate ]
stage: ai_coding
documentation_link: "../../../user/duo_agent_platform/customize/review_instructions#configure-custom-review-instructions-for-an-instance"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22616
categories: [ DAP Code Review ]
---

In previous versions of GitLab, you could only define custom review instructions for GitLab Duo at the project or group level.
Administrators who wanted consistent review guidance across an entire instance, such as security rules or internal coding standards, had to duplicate the same instructions in every project.

Now you can configure custom review instructions for an entire instance.

As an administrator, select a project in your instance to use as a template. When GitLab Duo performs a code review, it combines the instructions from the instance-level `.gitlab/duo/mr-review-instructions.yaml` file with any group-level and project-level instructions. This gives organizations a single source of truth for instance-wide review standards.

Both Code Review Flow and GitLab Duo Code Review support instance-level custom instructions.
