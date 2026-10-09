---
title: "Provide images as context for Developer Flow and Agentic Chat"
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
report or a diagram in a design discussion never reached the model. Now the Developer Flow and Agentic Chat can read
images in your repository and attachments on issues, merge requests, and comments, and use them as context.

You cannot upload an image directly in your prompt.
Instead, name an image that already exists:

- For a file in the repository, give the file path. For example, `docs/architecture.png`.
- For an attachment, give the upload reference as it appears in the Markdown.
  For example, `/uploads/<secret>/screenshot.png`.
