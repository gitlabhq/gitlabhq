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

The CI/CD Tunnel enables users to access Kubernetes clusters from GitLab CI/CD jobs even if there is no network
connectivity between GitLab Runner and a cluster. GitLab Runner does not have to be running in the same cluster.

Only CI/CD jobs set in the configuration project can access one of the configured agents.

## Prerequisites

- An existing Kubernetes cluster.
- An Agent [installed on your cluster](install/index.md).

## Use the CI/CD Tunnel to run Kubernetes commands from GitLab CI/CD

If your project has access to one or more Agent records available, its CI/CD
jobs provide a `KUBECONFIG` variable compatible with `kubectl`.

Also, each Agent has a separate context (`kubecontext`). By default,
there isn't any context selected.
Contexts are named in the following format: `<namespace>/<project-name>:<agent-name>`.
To get the list of available contexts, run `kubectl config get-contexts`.

## Share the CI/CD Tunnel provided by an Agent with other projects and groups

The Agent can be configured to enable access to the CI/CD Tunnel to other projects or all the projects under a given group. This way you can have a single agent serving all the requests for several projects saving on resources and maintenance.

You can read more on how to [authorize access in the Agent configuration reference](repository.md#authorize-projects-and-groups-to-use-an-agent).

## Restrict access of authorized projects and groups **(PREMIUM)**

You can [configure various impersonations](repository.md#use-impersonation-to-restrict-project-and-group-access) to restrict the permissions of a shared CI/CD Tunnel.

## Example for a `kubectl` command using the CI/CD Tunnel

The following example shows a CI/CD job that runs a `kubectl` command using the CI/CD Tunnel.
You can run any Kubernetes-specific commands similarly, such as `kubectl`, `helm`,
`kpt`, and so on. To do so:

1. Set your Agent's context in the first command with the format `<agent-configuration-project-path>:<agent-name>`.
1. Run Kubernetes commands.

For example:

```yaml
 deploy:
   image:
     name: bitnami/kubectl:latest
     entrypoint: [""]
   script:
   - kubectl config use-context path/to/agent-configuration-project:your-agent-name
   - kubectl get pods
```
