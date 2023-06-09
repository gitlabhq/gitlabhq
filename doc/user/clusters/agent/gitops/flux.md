---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Flux (Beta) **(FREE)**

Flux is a GitOps tool that helps you manage your Kubernetes clusters.
You can use Flux to:

- Keep your clusters in sync with your Git repositories.
- Reconcile code changes with your deployments.
- Manage your Flux installation itself with a bootstrap.

You can use the agent for Kubernetes with Flux to:

- Trigger immediate Git repository reconciliation.

To get started, see the [Flux installation documentation](https://fluxcd.io/flux/installation).

Support for Flux is in [Beta](../../../../policy/experiment-beta-support.md#beta).

## Bootstrap installation

Use the Flux command [`bootstrap gitlab`](https://fluxcd.io/flux/installation/#gitlab-and-gitlab-enterprise)
to configure a Kubernetes cluster to manage itself from a Git repository.

You must authenticate your installation with either:

- Recommended. [A project access token](../../../project/settings/project_access_tokens.md).
- A [group access token](../../../group/settings/group_access_tokens.md).
- A [personal access token](../../../profile/personal_access_tokens.md).

Some Flux features like [automated image updates](https://fluxcd.io/flux/guides/image-update/) require
write access to the source repositories.

## GitOps repository structure

You should organize your repositories to meet the needs of your team. For detailed recommendations, see the Flux [repository structure documentation](https://fluxcd.io/flux/guides/repository-structure/).

## Immediate Git repository reconciliation

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/392852) in GitLab 16.1.

Usually, the Flux source controller reconciles Git repositories at configured intervals.
This can cause delays between a `git push` and the reconciliation of the cluster state, and results in
unnecessary pulls from GitLab.

The agent for Kubernetes automatically detects Flux `GitRepository` objects that
reference GitLab projects in the instance the agent is connected to,
and configures a [`Receiver`](https://fluxcd.io/flux/components/notification/receiver/) for the instance.
When the agent for Kubernetes detects a `git push`, the `Receiver` is triggered
and Flux reconciles the cluster with any changes to the repository.

To use immediate Git repository reconciliation, you must have a Kubernetes cluster that runs:

- The agent for Kubernetes.
- Flux `source-controller` and `notification-controller`.

Immediate Git repository reconciliation can reduce the time between a push and reconciliation,
but it doesn't guarantee that every `git push` event is received. You should still set
[`GitRepository.spec.interval`](https://fluxcd.io/flux/components/source/gitrepositories/#interval)
to an acceptable duration.

### Custom webhook endpoints

When the agent for Kubernetes calls the `Receiver` webhook,
the agent defaults to `http://webhook-receiver.flux-system.svc.cluster.local`,
which is also the default set by a Flux bootstrap installation. To configure a custom
endpoint, set `flux.webhook_receiver_url` to a URL that the agent can resolve. For example:

```yaml
flux:
  webhook_receiver_url: http://webhook-receiver.another-flux-namespace.svc.cluster.local
```

There is special handing for
[service proxy URIs](https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster-services/) configured
in this format: `/api/v1/namespaces/[^/]+/services/[^/]+/proxy`. For example:

```yaml
flux:
  webhook_receiver_url: /api/v1/namespaces/flux-system/services/http:webhook-receiver:80/proxy
```

In these cases, the agent for Kubernetes uses the available Kubernetes configuration
and context to connect to the API endpoint.
You can use this if you run an agent outside a cluster
and you haven't [configured an `Ingress`](https://fluxcd.io/flux/guides/webhook-receivers/#expose-the-webhook-receiver)
for the Flux notification controller.

WARNING:
You should configure only trusted service proxy URIs.
When the agent for Kubernetes provides a service proxy URI,
it sends typical Kubernetes API requests which include
the credentials necessary to authenticate with the API service.
