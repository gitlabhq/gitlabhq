---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# CI/CD Tunnel

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/327409) in GitLab 14.1.
> - Pre-configured `KUBECONFIG` [added](https://gitlab.com/gitlab-org/gitlab/-/issues/324275) in GitLab 14.2.

The CI/CD Tunnel enables users to access Kubernetes clusters from GitLab CI/CD jobs even if there is no network
connectivity between GitLab Runner and a cluster. GitLab Runner does not have to be running in the same cluster.

Only CI/CD jobs set in the configuration project can access one of the configured agents.

Prerequisites:

- A running [`kas` instance](index.md#set-up-the-kubernetes-agent-server).
- A [configuration repository](index.md#define-a-configuration-repository) with an Agent config file
  installed (`.gitlab/agents/<agent-name>/config.yaml`).
- An [Agent record](index.md#create-an-agent-record-in-gitlab).
- The agent is [installed in the cluster](index.md#install-the-agent-into-the-cluster).

If your project has one or more Agent records, a `KUBECONFIG` variable that is compatible with `kubectl` is provided to your CI/CD jobs. A separate context (`kubecontext`) is available for each configured Agent. By default, no context is selected.

Contexts are named in the following format: `<agent-configuration-project-path>:<agent-name>`.

To access your cluster from a CI/CD job through the tunnel:

1. In your `.gitlab-ci.yml` select the context for the agent you wish to use:

   ```yaml
   deploy:
     image:
       name: bitnami/kubectl:latest
       entrypoint: [""]
     script:
     - kubectl config use-context path/to/agent-configuration-project:your-agent-name
     - kubectl get pods
   ```

1. Execute `kubectl` commands directly against your cluster with this CI/CD job you just created.
