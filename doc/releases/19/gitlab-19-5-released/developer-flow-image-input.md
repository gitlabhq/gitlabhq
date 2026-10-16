---
title: "Provide images as context for Developer Flow and Agentic Chat in your IDE"
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/project/merge_requests/developer/#provide-images-as-context"
work_item: https://gitlab.com/groups/gitlab-org/modelops/applied-ml/code-suggestions/-/work_items/61
categories: [ Duo Developer ]
level: secondary
weight: 50
---

In previous versions of GitLab, the Developer Flow and Agentic Chat could only read text, so a screenshot on a bug
report or a diagram in a design discussion never reached the model. Now the Developer Flow, including when you start
it from Agentic Chat, and Agentic Chat in your IDE can read images in your repository and attachments on issues,
merge requests, and comments in the same project, and use them as context.

You cannot upload an image directly in your prompt. Instead, name an image that already exists, by its file path in
the repository or by its upload reference. For details, see the documentation.
