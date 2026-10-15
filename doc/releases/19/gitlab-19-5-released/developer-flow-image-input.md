---
title: "Image context in GitLab Duo CLI"
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/gitlab_duo_cli/use/#provide-images-as-context"
work_item: https://gitlab.com/groups/gitlab-org/modelops/applied-ml/code-suggestions/-/work_items/61
categories: [ Duo Developer ]
level: secondary
weight: 50
---

Previously, GitLab Duo CLI could read text files but could not use screenshots or diagrams as context.
Now, when you run the CLI locally in interactive or headless mode, it can read images from your
repository and attachments on issues, merge requests, and comments in the same project.

Image context requires GitLab Duo CLI 9.27.0 or later and a GitLab-managed model.
