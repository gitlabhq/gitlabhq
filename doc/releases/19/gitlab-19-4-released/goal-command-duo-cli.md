---
title: "/goal command in GitLab Duo CLI"
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_clients
documentation_link: "../../../user/gitlab_duo_cli/use/#slash-commands"
work_item: https://gitlab.com/groups/gitlab-org/ai-powered/-/work_items/10
categories: [ Duo CLI ]
level: secondary
weight: 50
---

GitLab Duo CLI now includes a `/goal` slash command that delegates open-ended objectives to a
governed, goal-driven flow that runs locally.

You describe a goal and GitLab Duo handles implementation and verification, using an
independent judge to decide when you have achieved your goal or reached the iteration limit. You
stay in control the whole time: pause, update the goal, or redirect the agent at any time.

The `/goal` slash command requires GitLab 19.3 and later, and GitLab Duo CLI 9.17.0 and later.

To get started, run `/goal <task>`. 

For example:

```plaintext
/goal Fix the failing tests in spec/models/user_spec.rb
```
