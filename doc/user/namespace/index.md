---
stage: Manage
group: Workspace
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Namespaces

In GitLab, a namespace is a unique name for a user, a [group](../group/index.md), or [subgroup](../group/subgroups/index.md) under
which a project can be created.

For example, consider a user named Alex:

| GitLab URL | Namespace |
| ---------- | --------- |
| Alex creates an account with the username `alex`: `https://gitlab.example.com/alex`. | The namespace in this case is `alex`. |
| Alex [creates a group](../group/manage.md#create-a-group) for their team with the group name `alex-team`. The group and its projects are available at: `https://gitlab.example.com/alex-team`. | The namespace in this case is `alex-team`. |
| Alex [creates a subgroup](../group/subgroups/index.md#create-a-subgroup) of `alex-team` with the subgroup name `marketing`. The subgroup and its projects are available at: `https://gitlab.example.com/alex-team/marketing`. | The namespace in this case is `alex-team/marketing`. |
