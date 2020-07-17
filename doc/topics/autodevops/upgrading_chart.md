# Upgrading auto-deploy-app chart for Auto DevOps

Auto DevOps provides the auto-deploy-app chart for deploying your application to the
Kubernetes cluster with Helm/Tiller. Major version changes of this chart could have
a significantly different resource architecture, and may not be backwards compatible.

This guide provides instructions on how to upgrade your deployments to use the latest
chart and resource architecture.

## Compatibility

The following table lists the version compatibility between GitLab and [auto-deploy-image](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image) (with the [auto-deploy-app chart](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app)).

| GitLab version   | auto-deploy-image version | Notes                                      |
|------------------|---------------------------|--------------------------------------------|
| v10.0 and higher | v0.1.0 and higher         | v0 and v1 charts are backwards compatible. |

## Upgrade Guide

The Auto DevOps project must use the unmodified chart managed by GitLab.
[Customized charts](customize.md#custom-helm-chart) are unsupported.

### v1 chart

The v1 chart is backward compatible with the v0 chart, so no configuration changes are needed.

## Troubleshooting

### Major version mismatch warning

If deploying a chart that has a major version that is different from the previous one,
the new chart might not be correctly deployed. This could be due to an architectural
change. If that happens, the deployment job fails with a message similar to:

```plaintext
*************************************************************************************
                                   [WARNING]
Detected a major version difference between the the chart that is currently deploying (auto-deploy-app-v0.7.0), and the previously deployed chart (auto-deploy-app-v1.0.0).
A new major version might not be backward compatible with the current release (production). The deployment could fail or be stuck in an unrecoverable status.
...
```

To clear this error message and resume deployments, you must do one of the following:

- Manually [upgrade the chart version](#upgrade-guide).
- [Use a specific chart version](#use-a-specific-chart-version).

#### Use a specific chart version

To use a specific chart version, you must specify a corresponding version of [auto-deploy-image](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image).
Do this by [customizing the image in your `.gitlab-ci.yml`](customize.md#customizing-gitlab-ciyml).

For example, create the following `.gitlab-ci.yml` file in the project. It configures Auto DevOps
to use [auto-deploy-image](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image) version `v0.17.0`
for deployment jobs. It will download the chart from [chart repository](https://charts.gitlab.io/):

```yaml
include:
  - template: Auto-DevOps.gitlab-ci.yml

.auto-deploy:
  image: "registry.gitlab.com/gitlab-org/cluster-integration/auto-deploy-image:v0.17.0"
```

### Ignore warning and continue deploying

If you are certain that the new chart version is safe to be deployed,
you can add the `AUTO_DEVOPS_ALLOW_TO_FORCE_DEPLOY_V<N>` [environment variable](customize.md#build-and-deployment)
to force the deployment to continue, where `<N>` is the major version.

For example, if you want to deploy the v2.0.0 chart on a deployment that previously
used the v0.17.0 chart, add `AUTO_DEVOPS_ALLOW_TO_FORCE_DEPLOY_V2`.
