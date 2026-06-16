---
title: New event triggers for flows and external agents
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Premium, Ultimate ]
documentation_link: "../../../user/duo_agent_platform/triggers/#create-a-trigger"
categories: [ Duo Agent Platform ]
level: secondary
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21997
stage: ai-powered
ignore_in_report: true
---

<!-- categories: Duo Agent Platform -->

In previous versions of GitLab, you could only run flows and external agents when the service account was mentioned, assigned, or added as a reviewer. Coordinating automation around the
rest of the merge request lifecycle, or around work item creation, required external glue.

You can now configure triggers for four additional events:

- **Merge request ready**: A user marks a draft merge request as ready for review. Previously released behind a feature flag, this event trigger is now generally available.
- **Merge request code conflict**: A merge request can no longer be merged because of a code conflict.
- **Merge request approved**: A merge request receives all its required approvals.
- **Work item created**: A user creates a work item in the project.

To configure a trigger, go to **AI** > **Triggers** in your project, or select one when you enable a flow. 
