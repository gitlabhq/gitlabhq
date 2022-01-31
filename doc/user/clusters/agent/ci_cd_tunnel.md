---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# CI/CD Tunnel **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/327409) in GitLab 14.1.
> - The pre-configured `KUBECONFIG` was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/324275) in GitLab 14.2.
> - The ability to authorize groups was [introduced](https://gitlab.com/groups/gitlab-org/-/epics/5784) in GitLab 14.3.
> - [Moved](https://gitlab.com/groups/gitlab-org/-/epics/6290) to GitLab Free in 14.5.
> - Support for Omnibus installations was [introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5686) in GitLab 14.5.

To use GitLab CI/CD to safely deploy your application to a cluster, you can use the CI/CD Tunnel.

You can authorize multiple projects to access the same cluster, so you
can keep your application's codebase in one repository and configure
your cluster in another. This method is scalable and can save you resources.

To ensure access to your cluster is safe, only the projects you
authorize can access your Agent through the CI/CD Tunnel.

## Prerequisites

To use the CI/CD Tunnel, you need an existing Kubernetes cluster connected to GitLab through the
[GitLab Agent](install/index.md#install-the-agent-onto-the-cluster).

To run your CI/CD jobs using the CI/CD Tunnel, you do not need to have a runner in the same cluster.

## How the CI/CD Tunnel works

When you authorize a project to use an Agent, the Tunnel automatically
injects a `KUBECONFIG` variable into its CI/CD jobs. This way, you can
run `kubectl` commands from GitLab CI/CD scripts that belong to the
authorized project.

When you authorize a group, all the projects that belong to that group
become authorized to access the selected Agent.

An Agent can only authorize projects or groups in the same group
hierarchy as the Agent's configuration project. You can authorize
up to 100 projects and 100 groups per Agent.

Also, each Agent has a separate context (`kubecontext`).
The Tunnel uses this information to safely allow access to the cluster from
jobs running in the projects you authorized.

## Configure the CI/CD Tunnel

The CI/CD Tunnel is configured directly through the
Agent's configuration file ([`config.yaml`](repository.md)) to:

- Authorize [projects](repository.md#authorize-projects-to-use-an-agent) and [groups](repository.md#authorize-groups-to-use-an-agent) to use the same Agent.
- [Run `kubectl` commands using the CI/CD Tunnel](repository.md#run-kubectl-commands-using-the-cicd-tunnel).
- [Restrict access of authorized projects and groups through impersonation strategies](repository.md#use-impersonation-to-restrict-project-and-group-access).
