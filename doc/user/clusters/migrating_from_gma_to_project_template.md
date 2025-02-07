---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrate from GitLab Managed Apps to Cluster Management Projects (deprecated)
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

The GitLab Managed Apps were deprecated in GitLab 14.0
in favor of user-controlled Cluster Management projects.
Managing your cluster applications through a project enables you a
lot more flexibility to manage your cluster than through the late GitLab Managed Apps.
To migrate to the cluster management project you need
[GitLab Runners](../../ci/runners/_index.md)
available and be familiar with [Helm](https://helm.sh/).

## Migrate to a Cluster Management Project

To migrate from GitLab Managed Apps to a Cluster Management Project,
follow the steps below.
See also [video walk-throughs](#video-walk-throughs) with examples.

1. Create a new project based on the [Cluster Management Project template](management_project_template.md#create-a-project-based-on-the-cluster-management-project-template).
1. [Install an agent](agent/install/_index.md) for this project in your cluster.
1. Set the `KUBE_CONTEXT` CI/CD variable to the newly installed agent's context, as instructed in the `.gitlab-ci.yml` from the Project Template.
1. Detect apps deployed through Helm v2 releases by using the pre-configured [`.gitlab-ci.yml`](management_project_template.md#the-gitlab-ciyml-file) file:

   - In case you had overwritten the default GitLab Managed Apps namespace, edit `.gitlab-ci.yml`,
     and make sure the script is receiving the correct namespace as an argument:

     ```yaml
     script:
       - gl-fail-if-helm2-releases-exist <your_custom_namespace>
     ```

   - If you kept the default name (`gitlab-managed-apps`), then the script is already
     set up.

   Either way, [run a pipeline manually](../../ci/pipelines/_index.md#run-a-pipeline-manually) and read the logs of the
   `detect-helm2-releases` job to know if you have any Helm v2 releases and which are they.

1. If you have no Helm v2 releases, skip this step. Otherwise, follow the official Helm documentation on
   [how to migrate from Helm v2 to Helm v3](https://helm.sh/blog/migrate-from-helm-v2-to-helm-v3/),
   and clean up the Helm v2 releases after you are confident that they have been successfully migrated.

1. In this step you should already have only Helm v3 releases.
   Uncomment from the main [`./helmfile.yaml`](management_project_template.md#the-main-helmfileyml-file) the paths for the
   applications that you would like to manage with this project. Although you could uncomment all the ones you want to
   managed at once, you should repeat the following steps separately for each app, so you do not get lost during
   the process.
1. Edit the associated `applications/{app}/helmfiles.yaml` to match the chart version deployed
   for your app. Take a GitLab Runner Helm v3 release as an example:

   The following command lists the releases and their versions:

   ```shell
   helm ls -n gitlab-managed-apps

   NAME NAMESPACE REVISION UPDATED STATUS CHART APP VERSION
   runner gitlab-managed-apps 1 2021-06-09 19:36:55.739141644 +0000 UTC deployed gitlab-runner-0.28.0 13.11.0
   ```

   Take the version from the `CHART` column which is in the format `{release}-v{chart_version}`,
   then edit the `version:` attribute in the `./applications/gitlab-runner/helmfile.yaml`, so that it matches the version
   you have deployed. This is a safe step to avoid upgrading versions during this migration.
   Make sure you replace `gitlab-managed-apps` from the above command if you have your apps deployed to a different
   namespace.

1. Edit the `applications/{app}/values.yaml` associated with your app to match the
   deployed values. For example, for GitLab Runner:

   1. Copy the output of the following command (it might be big):

      ```shell
      helm get values runner -n gitlab-managed-apps -a --output yaml
      ```

   1. Overwrite `applications/gitlab-runner/values.yaml` with the output of the previous command.

   This safe step guarantees that no unexpected default values overwrite your deployed values.
   For instance, your GitLab Runner could have its `gitlabUrl` or `runnerRegistrationToken` overwritten by mistake.

1. Some apps require special attention:

   - Ingress: Due to an existing [chart issue](https://github.com/helm/charts/pull/13646), you might see
     `spec.clusterIP: Invalid value` when trying to run the [`./gl-helmfile`](management_project_template.md#the-gitlab-ciyml-file)
     command. To work around this, after overwriting the release values in `applications/ingress/values.yaml`,
     you might need to overwrite all the occurrences of `omitClusterIP: false`, setting it to `omitClusterIP: true`.
     Another approach,could be to collect these IPs by running `kubectl get services -n gitlab-managed-apps`
     and then overwriting each `ClusterIP` that it complains about with the value you got from that command.

   - Vault: This application introduces a breaking change from the chart we used in Helm v2 to the chart
     used in Helm v3. So, the only way to integrate it with this Cluster Management Project is to actually uninstall this app and accept the
     chart version proposed in `applications/vault/values.yaml`.

   - Cert-manager:

     - For users on Kubernetes version 1.20 or above, the deprecated cert-manager v0.10 is no longer valid
       and the upgrade includes a breaking change. So we suggest that you [backup and uninstall cert-manager v0.10](#backup-and-uninstall-cert-manager-v010),
       and install the latest cert-manager instead. To install this version, uncomment `applications/cert-manager/helmfile.yaml`
       from [`./helmfile.yaml`](management_project_template.md#the-main-helmfileyml-file).
       This triggers a pipeline to install the new version.
     - For users on Kubernetes versions lower than 1.20, you can stick to v0.10 by uncommenting
       `applications/cert-manager-legacy/helmfile.yaml`
       in your project's main Helmfile ([`./helmfile.yaml`](management_project_template.md#the-main-helmfileyml-file)).

       WARNING:
       Cert-manager v0.10 breaks when Kubernetes is upgraded to version 1.20 or later.

1. After following all the previous steps, [run a pipeline manually](../../ci/pipelines/_index.md#run-a-pipeline-manually)
   and watch the `apply` job logs to see if any of your applications were successfully detected, installed, and whether they got any
   unexpected updates.

   Some annotation checksums are expected to be updated, as well as this attribute:

   ```diff
   --- heritage: Tiller
   +++ heritage: Tiller
   ```

After getting a successful pipeline, repeat these steps for any other deployed apps
you want to manage with the Cluster Management Project.

## Backup and uninstall cert-manager v0.10

1. Follow the [official docs](https://cert-manager.io/docs/devops-tips/backup/) on how to
   backup your cert-manager v0.10 data.
1. Uninstall cert-manager by editing the setting all the occurrences of `installed: true` to `installed: false` in the
   `applications/cert-manager/helmfile.yaml` file.
1. Search for any left-over resources by executing the following command `kubectl get Issuers,ClusterIssuers,Certificates,CertificateRequests,Orders,Challenges,Secrets,ConfigMaps -n gitlab-managed-apps | grep certmanager`.
1. For each of the resources found in the previous step, delete them with `kubectl delete -n gitlab-managed-apps {ResourceType} {ResourceName}`.
   For example, if you found a resource of type `ConfigMap` named `cert-manager-controller`, delete it by executing:
   `kubectl delete configmap -n gitlab-managed-apps cert-manager-controller`.

## Video walk-throughs

You can watch these videos with examples on how to migrate from GMA to a Cluster Management project:

- [Migrating from scratch using a brand new cluster management project](https://youtu.be/jCUFGWT0jS0). Also covers Helm v2 apps migration.
- [Migrating from an existing GitLab managed apps CI/CD project](https://youtu.be/U2lbBGZjZmc).
