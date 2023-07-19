---
stage: Deploy
group: Environments
info: An example of how to structure a repository for GitOps deployments
---

# Example GitOps repository structure **(FREE)**

This page describes an example structure for a project that builds and deploys an application
to a Kubernetes cluster with [GitOps](https://about.gitlab.com/topics/gitops) and the
[GitLab agent for Kubernetes](../../agent/gitops.md).

You can find an example project that uses this structure
[in this GitLab repository](https://gitlab.com/tigerwnz/minimal-gitops-app). You can use the example project
as a starting point to create your own deployment project.

## Deployment workflow

The default branch is the single source of truth for your application and the
Kubernetes manifests that deploy it. To be reflected in a Kubernetes cluster,
a code or configuration change must exist in the default branch.

A GitLab agent for Kubernetes is installed in every Kubernetes cluster. The agent
is configured to sync manifests from a corresponding branch in the repository.
These branches represent the state of each cluster, and contain only commits that
exist in the default branch.

Changes are deployed by merging the default branch into the branch of a cluster.
The agent that watches the branch picks up the change and syncs it to the cluster.

For the actual deployment, the example project uses the GitLab agent for Kubernetes,
but you can also use other GitOps tools.

### Review apps

Ephemeral environments such as [review apps](../../../../ci/review_apps/index.md)
are deployed differently. Their configuration does not exist on the default branch,
and the changes are not meant to be deployed to a permanent environment. Review app
manifests are generated and deployed in a merge request feature branch, which is removed
when the MR is merged.

## Example deployment

The example project deploys to two permanent environments, staging and production,
which each have a dedicated Kubernetes cluster. A third cluster is used for ephemeral
review apps.

Each cluster has a corresponding branch that represents the current state of the cluster:
`_gitlab/agents/staging`, `_gitlab/agents/production` and `_gitlab/agents/review`. Each branch is
[protected](../../../../user/project/protected_branches.md) and
a [project access token](../../../../user/project/settings/project_access_tokens.md)
is created for each branch with a configuration that allows only the corresponding token to push to the branch.
This ensures that environment branches are updated only through the configured process.

Deployment branches are updated by CI/CD jobs. The access token that allows pushing to each
branch is configured as a [CI/CD variable](../../../../ci/variables/index.md). These variables
are protected, and only available to pipelines running on a protected branch.
The CI/CD job merges the default branch `main` into the deployment branch, and pushes
the deployment branch back to the repository using the provided token. To preserve the
commit history between both branches, the CI/CD job uses a fast-forward merge.

Each cluster has an agent for Kubernetes, and each agent is configured to
sync manifests from the branch corresponding to its cluster.
In your own project, you can different GitOps tool like Flux, or use the same configuration to deploy
to virtual machines with GitLab CI/CD.

### Application changes

The example project follows this process to deploy an application change:

1. A new feature branch is created with the desired changes. The pipeline builds an image,
   runs the test suite, and deploy the changes to a review app in the `review` cluster.
1. The feature branch is merged to `main` and the review app is removed.
1. Manifests are updated on `main` (either directly or via merge request) to point to an updated
   version of the deployed image. The pipeline automatically merges `main` into the `_gitlab/agents/staging`
   branch, which updates the `staging` cluster.
1. The `production` job is triggered manually, and merges `main` into the `_gitlab/agents/production` branch,
   deploying to the `production` cluster.
