# Deploy Boards

> [Introduced][ce-1589] in [GitLab Enterprise Edition Premium][ee] 9.0.

GitLab's Deploy Boards offer a consolidated view of the current health and
status of each CI [environment] running on [Kubernetes], displaying the status
of the pods in the deployment. Developers and other teammates can view the
progress and status of a rollout, pod by pod, in the workflow they already use
without any need to access Kubernetes.

## Overview

With Deploy Boards you can gain more insight into deploys with benefits such as:

- Following a deploy from the start, not just when it's done
- Watching the rollout of a build across multiple servers
- Finer state detail (Waiting, Deploying, Finished, Unknown)
- See canary deployments

Since Deploy Boards are tightly coupled with Kubernetes, there is some required
knowledge. In particular you should be familiar with:

- [Kubernetes pods](https://kubernetes.io/docs/user-guide/pods)
- [Kubernetes labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
- [Kubernetes namespaces](https://kubernetes.io/docs/user-guide/namespaces/)
- [Kubernetes canary deployments](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#canary-deployments)

Here's an example of a Deploy Board of the production environment.

![Deploy Boards landing page](img/deploy_boards_landing_page.png)

The squares represent pods in your Kubernetes cluster that are associated with
the given environment. Hovering above each square you can see the state of a
deploy rolling out. The percentage is the percent of the pods that are updated
to the latest release. The squares with dots represent canary deployment pods.

## Requirements

In order to gather the deployment status you need to label your deployments,
replica sets, and pods with the `app` key and use the `CI_ENVIRONMENT_SLUG` as
a value. Each project will need to have a unique namespace in Kubernetes as well.

![Deploy Boards Kubernetes Label](img/deploy_boards_kubernetes_label.png)

The complete requirements for Deploy Boards to display for a specific [environment] are:

1. You should have a Kubernetes cluster up and running.
1. GitLab Runner should be configured with the [Docker][docker-exec] or
   [Kubernetes][kube-exec] executor.
1. Configure the [Kubernetes service][kube-service] in your project for the
   cluster. The Kubernetes namespace is of particular note as you will need it
   for your deployment scripts (exposed by the `KUBE_NAMESPACE` env variable).
1. Ensure a Kubernetes label of `app: $CI_ENVIRONMENT_SLUG` is applied to the
   deployments, replica sets, and pods, where `$CI_ENVIRONMENT_SLUG` the value
   of the CI variable. This is so we can lookup the proper environment in a
   cluster/namespace which may have more than one. These resources should be
   contained in the namespace defined in the Kubernetes service setting.
   You can use an [Autodeploy] `.gitlab-ci.yml` template which has predefined
   stages and commands to use, and automatically applies the labeling.
1. To track canary deployments you need to label your deployments and pods
   with `track: canary`. This allows GitLab to discover whether deployment
   is stable or canary (temporary). Read more in the [Canary deployments](#canary-deployments)
   section.

Once all of the above are set up and the pipeline has run at least once,
navigate to the environments page under **Pipelines ➔ Environments**.

Deploy Boards are visible by default. You can explicitly click
the triangle next to their respective environment name in order to hide them.
GitLab will then query Kubernetes for the state of each node (e.g., waiting,
deploying, finished, unknown), and the Deploy Board status will finally appear.

GitLab will only display a Deploy Board for top-level environments. Foldered
environments like `review/*` (usually used for [Review Apps]) won't have a
Deploy Board attached to them.

## Canary deployments

When embracing [Continuous Delivery](https://en.wikipedia.org/wiki/Continuous_delivery),
a company needs to decide what type of deployment strategy to use. One of the
most popular strategies is canary deployments, where a small portion of the fleet
is updated to the new version first. This subset, the canaries, then serve as
the proverbial [canary in the coal mine](https://en.wiktionary.org/wiki/canary_in_a_coal_mine).
If there is a problem with the new version of the application, only a small
percentage of users are affected and the change can either be fixed or quickly
reverted.

To start using canary deployments, in addition to the
[requirements of Deploy Boards](#requirements), you also need to label your
deployments and pods with the `canary` label (`track: canary`).

In the end, depending on the deploy, the label should be either `stable` or `canary`.
This allows GitLab to discover whether deployment is stable or canary (temporary).
To get started quickly, you can use the [Autodeploy] template for canary deployments
that GitLab provides.

Canary deployments are marked with a yellow dot in the Deploy Board so that you
can easily notice them.

![Canary deployments on Deploy Board](img/deploy_boards_canary_deployments.png)

## Further reading

- [GitLab Autodeploy][autodeploy]
- [GitLab CI environment variables][variables]
- [Environments and deployments][environment]
- [Kubernetes deploy example][kube-deploy]

[ce-1589]: https://gitlab.com/gitlab-org/gitlab-ee/issues/1589 "Deploy Boards intial issue"
[ee]: https://about.gitlab.com/gitlab-ee/ "GitLab Enterprise Edition landing page"
[kube-deploy]: https://gitlab.com/gitlab-examples/kubernetes-deploy "Kubernetes deploy example project"
[kubernetes]: https://kubernetes.io "Kubernetes website"
[environment]: ../../ci/environments.md "Environments and deployments documentation"
[docker-exec]: https://docs.gitlab.com/runner/executors/docker.html "GitLab Runner Docker executor"
[kube-exec]: https://docs.gitlab.com/runner/executors/kubernetes.html "GitLab Runner Kubernetes executor"
[kube-service]: integrations/kubernetes.md "Kubernetes project service"
[review apps]: ../../ci/review_apps/index.md "Review Apps documentation"
[variables]: ../../ci/variables/README.md "GitLab CI variables"
[autodeploy]: ../../ci/autodeploy/index.md "GitLab Autodeploy"
[kube-image]: https://gitlab.com/gitlab-examples/kubernetes-deploy/container_registry "Kubernetes deploy Container Registry"
