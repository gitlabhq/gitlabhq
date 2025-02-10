---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Deploy boards (deprecated)
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Disabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/353410) in GitLab 15.0.

WARNING:
This feature was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.
[An epic exists](https://gitlab.com/groups/gitlab-org/-/epics/2493)
to add this functionality to the [agent](../clusters/agent/_index.md).

FLAG:
On GitLab Self-Managed, by default this feature is not available. To make it available, an administrator can [enable the feature flag](../../administration/feature_flags.md) named `certificate_based_clusters`.

GitLab deploy boards offer a consolidated view of the current health and
status of each CI [environment](../../ci/environments/_index.md) running on [Kubernetes](https://kubernetes.io), displaying the status
of the pods in the deployment. Developers and other teammates can view the
progress and status of a rollout, pod by pod, in the workflow they already use
without any need to access Kubernetes.

NOTE:
If you have a Kubernetes cluster, you can Auto Deploy applications to production
environments by using [Auto DevOps](../../topics/autodevops/_index.md).

## Overview

With deploy boards you can gain more insight into deploys with benefits such as:

- Following a deploy from the start, not just when it's done
- Watching the rollout of a build across multiple servers
- Finer state detail (Succeeded, Running, Failed, Pending, Unknown)
- See [Canary Deployments](canary_deployments.md)

Here's an example of a deploy board of the production environment.

![deploy boards landing page](img/deploy_boards_landing_page_v9_0.png)

The squares represent pods in your Kubernetes cluster that are associated with
the given environment. Hovering above each square you can see the state of a
deploy rolling out. The percentage is the percent of the pods that are updated
to the latest release.

Since deploy boards are tightly coupled with Kubernetes, there is some required
knowledge. In particular, you should be familiar with:

- [Kubernetes pods](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Kubernetes labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
- [Kubernetes namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [Kubernetes canary deployments](https://kubernetes.io/docs/concepts/workloads/management/#canary-deployments)

## Use cases

Since the deploy board is a visual representation of the Kubernetes pods for a
specific environment, there are a lot of use cases. To name a few:

- You want to promote what's running in staging, to production. You go to the
  environments list, verify that what's running in staging is what you think is
  running, then select the [manual job](../../ci/jobs/job_control.md#create-a-job-that-must-be-run-manually) to deploy to production.
- You trigger a deploy, and you have many containers to upgrade so you know
  this takes a while (you've also throttled your deploy to only take down X
  containers at a time). But you need to tell someone when it's deployed, so you
  go to the environments list, look at the production environment to see what
  the progress is in real-time as each pod is rolled.
- You get a report that something is weird in production, so you look at the
  production environment to see what is running, and if a deploy is ongoing or
  stuck or failed.
- You've got an MR that looks good, but you want to run it on staging because
  staging is set up in some way closer to production. You go to the environment
  list, find the [Review App](../../ci/review_apps/_index.md) you're interested in, and select the
  manual action to deploy it to staging.

## Enabling deploy boards

To display the deploy boards for a specific [environment](../../ci/environments/_index.md) you should:

1. Have [defined an environment](../../ci/environments/_index.md) with a deploy stage.

1. Have a Kubernetes cluster up and running.

   NOTE:
   If you're using OpenShift, ensure that you're using the `Deployment` resource
   instead of `DeploymentConfiguration`. Otherwise, the deploy boards don't render
   correctly. For more information, read the
   [OpenShift docs](https://docs.openshift.com/container-platform/3.7/dev_guide/deployments/kubernetes_deployments.html#kubernetes-deployments-vs-deployment-configurations)
   and [GitLab issue #4584](https://gitlab.com/gitlab-org/gitlab/-/issues/4584).

1. [Configure GitLab Runner](../../ci/runners/_index.md) with the [`docker`](https://docs.gitlab.com/runner/executors/docker.html) or
   [`kubernetes`](https://docs.gitlab.com/runner/executors/kubernetes/index.html) executor.
1. Configure the [Kubernetes integration](../infrastructure/clusters/_index.md) in your project for the
   cluster. The Kubernetes namespace is of particular note as you need it
   for your deployment scripts (exposed by the `KUBE_NAMESPACE` deployment variable).
1. Ensure Kubernetes annotations of `app.gitlab.com/env: $CI_ENVIRONMENT_SLUG`
   and `app.gitlab.com/app: $CI_PROJECT_PATH_SLUG` are applied to the
   deployments, replica sets, and pods, where `$CI_ENVIRONMENT_SLUG` and
   `$CI_PROJECT_PATH_SLUG` are the values of the CI/CD variables. This is so we can
   lookup the proper environment in a cluster/namespace which may have more
   than one. These resources should be contained in the namespace defined in
   the Kubernetes service setting. You can use an [Auto deploy](../../topics/autodevops/stages.md#auto-deploy) `.gitlab-ci.yml`
   template which has predefined stages and commands to use, and automatically
   applies the annotations. Each project must have a unique namespace in
   Kubernetes as well. The image below demonstrates how this is shown inside
   Kubernetes.

   If you use GCP to manage clusters, you can see the deployment details in GCP itself by navigating to **Workloads > deployment name > Details**:

   ![deploy boards Kubernetes Label](img/deploy_boards_kubernetes_label_v11_9.png)

Once all of the above are set up and the pipeline has run at least once,
go to the environments page under **Operate > Environments**.

Deploy boards are visible by default. You can explicitly select
the triangle next to their respective environment name to hide them.

### Example manifest file

The following example is an extract of a Kubernetes manifest deployment file, using the two annotations `app.gitlab.com/env` and `app.gitlab.com/app` to enable the **deploy boards**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: "APPLICATION_NAME"
  annotations:
    app.gitlab.com/app: ${CI_PROJECT_PATH_SLUG}
    app.gitlab.com/env: ${CI_ENVIRONMENT_SLUG}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: "APPLICATION_NAME"
  template:
    metadata:
      labels:
        app: "APPLICATION_NAME"
      annotations:
        app.gitlab.com/app: ${CI_PROJECT_PATH_SLUG}
        app.gitlab.com/env: ${CI_ENVIRONMENT_SLUG}
```

The annotations are applied to the deployments, replica sets, and pods. By changing the number of replicas, like `kubectl scale --replicas=3 deploy APPLICATION_NAME -n ${KUBE_NAMESPACE}`, you can follow the instances' pods from the board.

NOTE:
The YAML file is static. If you apply it using `kubectl apply`, you must
manually provide the project and environment slugs, or create a script to
replace the variables in the YAML before applying.

## Canary Deployments

A popular CI strategy, where a small portion of the fleet is updated to the new
version of your application.

[Read more about Canary Deployments.](canary_deployments.md)

## Further reading

- [GitLab Auto deploy](../../topics/autodevops/stages.md#auto-deploy)
- [GitLab CI/CD variables](../../ci/variables/_index.md)
- [Environments and deployments](../../ci/environments/_index.md)
- [Kubernetes deploy example](https://gitlab.com/gitlab-examples/kubernetes-deploy)
