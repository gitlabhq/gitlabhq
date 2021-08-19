---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Multiple Kubernetes clusters for Auto DevOps **(FREE)**

When using Auto DevOps, you can deploy different environments to
different Kubernetes clusters, due to the 1:1 connection
[existing between them](../../user/project/clusters/multiple_kubernetes_clusters.md).

The [Deploy Job template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml)
used by Auto DevOps defines 3 environment names:

- `review/` (every environment starting with `review/`)
- `staging`
- `production`

Those environments are tied to jobs using [Auto Deploy](stages.md#auto-deploy), so
except for the environment scope, they must have a different deployment domain.
You must define a separate `KUBE_INGRESS_BASE_DOMAIN` variable for each of the above
[based on the environment](../../ci/variables/index.md#limit-the-environment-scope-of-a-cicd-variable).

The following table is an example of how to configure the three different clusters:

| Cluster name | Cluster environment scope | `KUBE_INGRESS_BASE_DOMAIN` variable value | Variable environment scope | Notes |
|--------------|---------------------------|-------------------------------------------|----------------------------|---|
| review       | `review/*`                | `review.example.com`                      | `review/*`                 | The review cluster which runs all [Review Apps](../../ci/review_apps/index.md). `*` is a wildcard, used by every environment name starting with `review/`. |
| staging      | `staging`                 | `staging.example.com`                     | `staging`                  | (Optional) The staging cluster which runs the deployments of the staging environments. You must [enable it first](customize.md#deploy-policy-for-staging-and-production-environments). |
| production   | `production`              | `example.com`                             | `production`               | The production cluster which runs the production environment deployments. You can use [incremental rollouts](customize.md#incremental-rollout-to-production). |

To add a different cluster for each environment:

1. Navigate to your project's **Infrastructure > Kubernetes clusters**.
1. Create the Kubernetes clusters with their respective environment scope, as
   described from the table above.
1. After creating the clusters, navigate to each cluster and [install
   Ingress](quick_start_guide.md#install-ingress). Wait for the Ingress IP address to be assigned.
1. Make sure you've [configured your DNS](requirements.md#auto-devops-base-domain) with the
   specified Auto DevOps domains.
1. Navigate to each cluster's page, through **Infrastructure > Kubernetes clusters**,
   and add the domain based on its Ingress IP address.

After completing configuration, test your setup by creating a merge request.
Verify whether your application deployed as a Review App in the Kubernetes
cluster with the `review/*` environment scope. Similarly, check the
other environments.

[Cluster environment scope isn't respected](https://gitlab.com/gitlab-org/gitlab/-/issues/20351)
when checking for active Kubernetes clusters. For multi-cluster setup to work with Auto DevOps,
create a fallback cluster with **Cluster environment scope** set to `*`. A new cluster isn't
required. You can use any of the clusters already added.
