---
stage: Manage
group: Workspace
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Namespaces

In GitLab, a *namespace* organizes related projects together.
GitLab has two types of namespaces:

- A *personal* namespace, which is based on your username. Projects under a personal namespace must be configured one at a time.
- A *group* or *subgroup* namespace. In these namespaces, you can manage multiple projects at once.

To determine whether you're viewing a group or personal namespace, you can view the URL. For example:

| Namespace for | URL | Namespace |
| ------------- | --- | --------- |
| A user named `alex`. | `https://gitlab.example.com/alex` | `alex` |
| A group named `alex-team`. | `https://gitlab.example.com/alex-team` | `alex-team` |
| A group named `alex-team` with a subgroup named `marketing`. |  `https://gitlab.example.com/alex-team/marketing` | `alex-team/marketing` |
