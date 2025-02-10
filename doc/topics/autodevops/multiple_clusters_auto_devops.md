---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Multiple Kubernetes clusters for Auto DevOps
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

When using Auto DevOps, you can deploy different environments to different Kubernetes clusters.

The [Deploy Job template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml) used by Auto DevOps defines three environment names:

- `review/` (every environment starting with `review/`)
- `staging`
- `production`

These environments are tied to jobs using [Auto Deploy](stages.md#auto-deploy), so they must have different deployment domains. You must define separate [`KUBE_CONTEXT`](../../user/clusters/agent/ci_cd_workflow.md#environments-that-use-auto-devops) and [`KUBE_INGRESS_BASE_DOMAIN`](requirements.md#auto-devops-base-domain) variables for each of the three environments.

## Deploy to different clusters

To deploy your environments to different Kubernetes clusters:

1. [Create Kubernetes clusters](../../user/infrastructure/clusters/connect/new_gke_cluster.md).
1. Associate the clusters to your project:
   1. [Install a GitLab agent on each cluster](../../user/clusters/agent/_index.md).
   1. [Configure each agent to access your project](../../user/clusters/agent/work_with_agent.md#configure-your-agent).
1. [Install NGINX Ingress Controller](cloud_deployments/auto_devops_with_gke.md#install-ingress) in each cluster. Save the IP address and Kubernetes namespace for the next step.
1. [Configure the Auto DevOps CI/CD Pipeline variables](cicd_variables.md#build-and-deployment-variables)
   - Set up a `KUBE_CONTEXT` variable [for each environment](../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable). The value must point to the agent of the relevant cluster.
   - Set up a `KUBE_INGRESS_BASE_DOMAIN`. You must [configure the base domain](requirements.md#auto-devops-base-domain) for each environment to point to the Ingress of the relevant cluster.
   - Add a `KUBE_NAMESPACE` variable with a value of the Kubernetes namespace you want your deployments to target. You can scope the variable to multiple environments.

For deprecated, [certificate-based clusters](../../user/infrastructure/clusters/_index.md#certificate-based-kubernetes-integration-deprecated):

1. Go to the project and select **Operate > Kubernetes clusters** from the left sidebar.
1. [Set the environment scope of each cluster](../../user/project/clusters/multiple_kubernetes_clusters.md#setting-the-environment-scope).
1. For each cluster, [add a domain based on its Ingress IP address](../../user/project/clusters/gitlab_managed_clusters.md#base-domain).

NOTE:
[Cluster environment scope is not respected when checking for active Kubernetes clusters](https://gitlab.com/gitlab-org/gitlab/-/issues/20351). For a multi-cluster setup to work with Auto DevOps, you must create a fallback cluster with **Cluster environment scope** set to `*`. You can set any of the clusters you've already added as a fallback cluster.

### Example configurations

| Cluster name | Cluster environment scope | `KUBE_INGRESS_BASE_DOMAIN` value | `KUBE CONTEXT` value               | Variable environment scope | Notes |
| :------------| :-------------------------| :------------------------------- | :--------------------------------- | :--------------------------|:--|
| review       | `review/*`                | `review.example.com`             | `path/to/project:review-agent`     | `review/*`                 | A review cluster that runs all [review apps](../../ci/review_apps/_index.md). |
| staging      | `staging`                 | `staging.example.com`            | `path/to/project:staging-agent`    | `staging`                  | Optional. A staging cluster that runs the deployments of the staging environments. You must [enable it first](cicd_variables.md#deploy-policy-for-staging-and-production-environments). |
| production   | `production`              | `example.com`                    | `path/to/project:production-agent` | `production`               | A production cluster that runs the production environment deployments. You can use [incremental rollouts](cicd_variables.md#incremental-rollout-to-production). |

## Test your configuration

After completing configuration, test your setup by creating a merge request.
Verify whether your application deployed as a Review App in the Kubernetes
cluster with the `review/*` environment scope. Similarly, check the
other environments.
