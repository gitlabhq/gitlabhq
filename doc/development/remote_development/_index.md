---
stage: Create
group: Remote Development
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Remote Development Workspaces
---

Remote Development Workspaces provide cloud-based development environments that integrate with GitLab projects.
As a developer working on this feature, you create and maintain the infrastructure that users use to
spin up containerized development environments directly from their GitLab projects.

## Development workflow

When developing the Workspaces feature:

1. [Set up your local development environment](local_development_setup.md) with the necessary tools and dependencies.
1. [Deploy GitLab with workspaces using Helm chart](deployment_and_infrastructure.md) for testing.
1. [Understand workspace reconciliation logic](reconciliation_logic.md) that manages workspace state and lifecycle.

## Architecture and additional resources

For a deeper technical understanding, see the following resources:

- [Workspaces Handbook page](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/workspaces/)
- [Workspaces Architecture for Kubernetes setup](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/workspaces/architecture_kubernetes_setup/)
- [Workspaces Rails domain developer documentation](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/remote_development/README.md)
- [Workspaces examples](https://gitlab.com/gitlab-org/workspaces/examples)
- [User documentation](../../user/workspace/_index.md)
- [Development guide for Remote Development](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/remote_development/developing.md)
