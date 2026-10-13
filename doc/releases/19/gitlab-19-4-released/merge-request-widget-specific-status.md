---
title: Merge request widget is now more specific
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_coding
co_create: true
documentation_link: "../../../user/project/merge_requests/widgets/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251657
categories: [ Code Review Workflow ]
level: secondary
weight: 20
---

While GitLab checks a merge request, the widget now tells you. **Merge conflicts must be resolved**
becomes **Checking for merge conflicts** until the check finishes. When a rebase is refused, you
see the specific reason, such as **Source branch is protected from force push**, instead of a
generic retry prompt. You can act on the current state of the merge request.

The sticky title bar that stays visible while scrolling a merge request now also updates
immediately when you mark it draft or ready, instead of requiring a page refresh.

Thank you to the following users for these contributions!

- [Amartya Mishra](https://gitlab.com/Gamezordd) ([MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/253806) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251657))
- [Gerardo Navarro](https://gitlab.com/gerardo-navarro) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/252050))
- [Mahaveer A](https://gitlab.com/Mahaveer1013) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251290))
