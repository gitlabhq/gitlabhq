---
owning-stage: "~devops::create"
description: 'GitLab Remote Development ADR 100: New agent authorization strategy'
---

# GitLab Remote Development ADR 001: New agent authorization strategy

## Context

A decision was made to drop the legacy agent authorization strategy in favor of the new agent authorization strategy. As covered in [detailed proposal](https://gitlab.com/gitlab-org/remote-development/gitlab-remote-development-docs/-/blob/main/doc/proposal-for-mapping-projects-to-agents.md?ref_type=heads#problems-with-the-current-solution), the current solution has several issues that make it unsuitable for the long-term needs of the GitLab Remote Development feature. The main problems are:

1. **Limited flexibility**: The legacy agent authorization strategy relies on granting group-level Developer role to potential users. This makes it unsuitable for use in some organisations where users are not granted access at a group level.
1. **Potential security risks**: The legacy approach allows any user with Developer role within a limited scope to spin up a GitLab Agent and have it be potentially used for workspaces by users with relevant access to the project. Since workspaces contain privileged information such as secrets, more control should be enforced on what GitLab Agents may be select for hosting workspaces within a given scope (for e.g a group) as it is with GitLab CI Runners.

## Decision

Taking inspiration from the authorization model for GitLab CI Runners, a new authorization strategy for GitLab Agents will be introduced. In order understand how workspaces can be created using the new authorization strategy, it's important to understand the following rules:

- A user can only create workspaces using a cluster agent that is "available", and which has been configured for remote_development.
- A user must have Developer role to both the agent project and the workspace project.
- An agent is considered "available" for use with a workspace if a group owner or administrator has mapped the cluster agent to any parent group of the workspace project. Another way of looking at it is; a mapping between a cluster agent and a group is inherited by its subgroups.
- Mapping between a cluster agent and a group is a new concept that has been introduced with the revamped authorization strategy. A group owner may create a mapping between the group and any cluster agent residing within the group or its subgroup. **NOTE:** By default, no cluster agent is mapped to a group. Additionally, if a project resides within a group, it does NOT imply that the cluster agents of this project are mapped to the parent group(s).

In addition the above, the first phase of delivery will have the following restrictions:

- A GitLab Agent may only be mapped to a group. In the future, mapping cluster agents to the instance, user namespaces etc. can/should be explored.
- A GitLab Agent may only be mapped to a parent group. The group in question may or may not be a direct parent. For eg. if an agent belongs to a project with path `root-group/nested-group/agent-project`, then the agent may be mapped to either `root-group` and/or `nested-group`. In the future, there may be a need to consider mapping agents to a non-parent group. However, this will increase the scope of the task significantly due to additional considerations: for example, what if some owners/maintainers of a group do not access to the agent being mapped? This is not a problem when the agent is contained within the group. However, this usecase will have to be thought through if such a capability must be supported consistently.

For more details, on the details of the new authorization strategy, please refer to the [detailed technical design](https://gitlab.com/gitlab-org/remote-development/gitlab-remote-development-docs/-/blob/e28003334fda100295ed41bd84eef2b1770d86af/doc/tech-designs/2024-01-23-support-group-agent-authorization.md).

## Consequences

Since the new strategy is incompatible with the legacy authorization strategy, this feature will be put behind a feature flag and rolled out gradually. Additionally, in order to provide a smooth user experience during feature rollout, a one-time data migration will take place to create mappings between root groups and remote development cluster agents within these groups. After this migration, for any changes desired to the list of cluster agents available during workspace creation, users will be required to explicitly create/delete mappings.

## Alternatives

NA
