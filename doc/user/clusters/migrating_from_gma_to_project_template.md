---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Migrating from GitLab Managed Apps to a management project template

The [GitLab Managed Apps](applications.md) are deprecated in GitLab 14.0. To migrate to the new way of managing them:

1. Read how the [management project template](management_project_template.md) works, and
   create a new project based on the "GitLab Cluster Management" template.
1. Create a new project as explained in the [management project template](management_project_template.md).
1. Detect apps deployed through Helm v2 releases by using the pre-configured [`.gitlab-ci.yml`](management_project_template.md#the-gitlab-ciyml-file) file:
    - In case you had overwritten the default GitLab Managed Apps namespace, edit `.gitlab-ci.yml`,
      and make sure the script is receiving the correct namespace as an argument:

      ```yaml
      script:
        - gl-fail-if-helm2-releases-exist <your_custom_namespace>
      ```

    - If you kept the default name (`gitlab-managed-apps`), then the script is already
      set up.

   Either way, [run a pipeline manually](../../ci/pipelines/index.md#run-a-pipeline-manually) and read the logs of the
   `detect-helm2-releases` job to know if you have any Helm v2 releases and which are they.

1. If you have no Helm v2 releases, skip this step. Otherwise, follow the official Helm docs on
   [how to migrate from Helm v2 to Helm v3](https://helm.sh/blog/migrate-from-helm-v2-to-helm-v3/),
   and clean up the Helm v2 releases after you are confident that they have been successfully migrated.

1. In this step you should already have only Helm v3 releases.
   Uncomment from the main [`./helmfile.yaml`](management_project_template.md#the-main-helmfileyml-file) the paths for the
   applications that you would like to manage with this project. Although you could uncomment all the ones you want to
   managed at once, we recommend you repeat the following steps separately for each app, so you do not get lost during
   the process.
1. Edit the associated `applications/{app}/helmfiles.yaml` to match the chart version currently deployed
   for your app. Take a GitLab Runner Helm v3 release as an example:

   The following command lists the releases and their versions:

   ```shell
   helm ls -n gitlab-managed-apps
   
   NAME NAMESPACE REVISION UPDATED STATUS CHART APP VERSION
   runner gitlab-managed-apps 1 2021-06-09 19:36:55.739141644 +0000 UTC deployed gitlab-runner-0.28.0 13.11.0
   ```

   Take the version from the `CHART` column which is in the format `{release}-v{chart_version}`,
   then edit the `version:` attribute in the `./applications/gitlab-runner/helmfile.yaml`, so that it matches the version
   you have currently deployed. This is a safe step to avoid upgrading versions during this migration.
   Make sure you replace `gitlab-managed-apps` from the above command if you have your apps deployed to a different
   namespace.

1. Edit the `applications/{app}/values.yaml` associated with your app to match the currently
   deployed values. For example, for GitLab Runner:

    1. Copy the output of the following command (it might be big):

   ```shell
   helm get values runner -n gitlab-managed-apps -a --output yaml
   ```

    1. Overwrite `applications/gitlab-runner/values.yaml` with the output of the previous command.

   This safe step will guarantee that no unexpected default values overwrite your currently deployed values.
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

1. After following all the previous steps, [run a pipeline manually](../../ci/pipelines/index.md#run-a-pipeline-manually)
   and watch the `apply` job logs to see if any of your applications were successfully detected, installed, and whether they got any
   unexpected updates.

   Some annotation checksums are expected to be updated, as well as this attribute:

   ```diff
   --- heritage: Tiller
   +++ heritage: Tiller
   ```

After getting a successful pipeline, repeat these steps for any other deployed apps
you want to manage with the Cluster Management Project.
