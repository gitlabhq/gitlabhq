---
title: Customize default merge request titles
stage: create
level: secondary
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed ]
documentation_link: "../../../user/project/merge_requests/title_templates/"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/16080"
categories: [ Code Review Workflow ]
weight: 100
---

In previous versions of GitLab, the default title for a new merge request came from the
source branch or first commit, and you couldn't enforce a consistent naming convention
across your project.

Now you can configure a default merge request title template per project. Templates
support variables for the source branch, target branch, first commit subject, linked
issue ID, issue title, and a human-readable version of the source branch name. For example, the template
`Resolve %{issue_id} "%{issue_title}"` produces titles like `Resolve 123 "Fix login bug"`.
You can still edit the title before creating the merge request.
