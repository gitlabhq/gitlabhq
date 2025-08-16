---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
description: "This page lists a number of tips and tricks we have found useful in day to day end-to-end test level related tasks."
title: "Test Governance Tips and Tricks"
---

## Overview

This page lists a number of tips and tricks we have found useful in day to day Quality Engineering related
tasks.

## Running GitLab-QA pipeline against a specific GitLab release

While working on the [GitLab-QA codebase](https://gitlab.com/gitlab-org/gitlab-qa), it is sometimes helpful to run the GitLab-QA pipeline
against a specific release of the [GitLab project](https://gitlab.com/gitlab-org/gitlab). This could be
due reasons such as that particular GitLab release containing specific code needed for validating the changes made
in GitLab-QA. To run a [GitLab-QA pipeline](https://gitlab.com/gitlab-org/gitlab-qa/pipelines) against
a specific GitLab release, we need to know the GitLab release version created and tagged by the omnibus pipeline.
This can be found by either observing the `RELEASE` variable in any of the `test-on-omnibus` test jobs or
in the last output line of the `Trigger:gitlab-docker` job triggered by the `test-on-omnibus` job. Here is an example of what the `RELEASE` string
looks like:

```shell
registry.gitlab.com/gitlab-org/omnibus-gitlab/gitlab-ee:41b42271ff37bf79066ef3089432ee28cfd81d8c
```

Copy this string and create a new [GitLab-QA pipeline](https://gitlab.com/gitlab-org/gitlab-qa/pipelines)
with a `RELEASE` variable and use the copied string as its value. Create another variable called `QA_IMAGE` and set it to the value
that can be found in the `test-on-omnibus` upstream job. Here is an example of what the `QA_IMAGE` string looks like:

```shell
 registry.gitlab.com/gitlab-org/gitlab/gitlab-ee-qa:qa-shl-use-unique-group-for-access-termination-specs
```

Note that the string is the same as `RELEASE` except for the `-qa` suffix on the image name and the tag which is the branch name on the GitLab project.

Now run the pipeline against the branch that has your changes.

It's also possible to trigger a manual GitLab-QA pipeline against a specific [GitLab environment](https://handbook.gitlab.com/handbook/engineering/testing/end-to-end-pipeline-monitoring/) using the `RELEASE` and `QA_IMAGE` variable from the `test-on-omnibus` job of GitLab Merge Request.
For example, here is the link to run a manual GitLab QA pipeline [against Staging](https://ops.gitlab.net/gitlab-org/quality/staging/-/pipelines/new?var[RELEASE]=%27insert_docker_release_image_name_from_the_MR%27&var[QA_IMAGE]=%27insert_docker_qa_image_name_from_the_MR%27&var[GITLAB_QA_CONTAINER_REGISTRY_ACCESS_TOKEN]=%27insert_gitlab_qa_user_production_access_token%27).

- Note: If `registry.gitlab.com` is used, you will also need to include the `GITLAB_QA_CONTAINER_REGISTRY_ACCESS_TOKEN` variable with the value set to the production `gitlab-qa` user's access token to avoid authentication errors.

## Running end-to-end test pipelines using code from a specific GitLab-QA branch

### Running from a specific GitLab-QA branch against a live environment

It is often needed to test the impact of changes in the [GitLab-QA codebase](https://gitlab.com/gitlab-org/gitlab-qa) on
[`gitlab-org/gitlab` nightly schedule pipeline](https://gitlab.com/gitlab-org/gitlab/-/pipeline_schedules), [Staging](https://ops.gitlab.net/gitlab-org/quality/staging/-/pipelines),
[Pre-Prod](https://ops.gitlab.net/gitlab-org/quality/preprod/-/pipelines), [Canary](https://ops.gitlab.net/gitlab-org/quality/canary/-/pipelines)
or [Production](https://ops.gitlab.net/gitlab-org/quality/production/-/pipelines) pipelines.
This can be achieved by manually triggering a pipeline in any of these projects and setting the `QA_BRANCH` variable to the branch name you are working on in the [GitLab-QA project](https://gitlab.com/gitlab-org/gitlab-qa).
As a result, the pipeline will checkout the specified branch and build the `gitlab-qa` gem instead of using the latest published gem.

### Running from a specific GitLab-QA branch against a GitLab branch MR

You can checkout a test branch and edit the `Gemfile` to change the `gitlab-qa` line to install via the GitLab-QA branch.

For example in the `qa/gemfile`:

```console
gem 'gitlab-qa', git: 'https://gitlab.com/gitlab-org/gitlab-qa.git', branch: '<GitLab-QA-branch>'
```

Make sure to also `bundle install` and commit the `Gemfile.lock` as well.
Doing so successfully will allow the `gitlab-qa` gem to be built from a custom branch.

## Configure VS Code for GitLab-qa debugging

The [Ruby LSP VS Code extension](https://marketplace.visualstudio.com/items?itemName=Shopify.ruby-lsp) adds a few Ruby-related capabilities to VS Code, including the ability to debug Ruby code.

After you install the extension you can use VS Code to debug end-to-end specs running against your local GDK. You will need to add a Run configuration to `launch.json`. For example, the following `launch.json` will add a configuration named `Debug Test::Instance::All current file` to the list in the Run view of your Sidebar. Then, with a spec file open in the editor you can start debugging (F5) and VS Code will run the tests in the spec file.

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug Test::Instance::All current file",
      "type": "ruby_lsp",
      "request": "launch",
      "useBundler": true,
      "pathToBundler": "<path_to_bundler>",
      "cwd": "${workspaceRoot}/qa",
      "program": "${workspaceRoot}/qa/bin/qa",
      "env": {
        "CHROME_HEADLESS": "false",
        "QA_DEBUG": "true"
      },
      "args": [
          "Test::Instance::All",
          "http://localhost:3000",
          "--",
          "${file}"
      ]
    }
  ]
}
```

You can include multiple configurations, and any environment variables or command line options can be included. For example, here's one that will debug smoke tests while running them on Staging:

```json
{
  "name": "Debug Staging Smoke tests",
  "type": "Ruby",
  "request": "launch",
  "useBundler": true,
  "pathToBundler": "<path_to_bundler>",
  "cwd": "${workspaceRoot}/qa",
  "program": "${workspaceRoot}/qa/bin/qa",
  "env": {
    "CHROME_HEADLESS": "false",
    "QA_DEBUG": "true",
    "GITLAB_USERNAME": "gitlab-qa",
    "GITLAB_PASSWORD": "from 1Password",
    "GITLAB_QA_ACCESS_TOKEN": "from 1Password"
  },
  "args": [
      "Test::Instance::All",
      "https://staging.gitlab.com",
      "--",
      "--tag", "smoke"
  ]
}
```

## Set up experimental auto-scaled runners

Sometimes, it's useful to [deploy auto-scaled runners to try out and compare different machine types](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/10623).

To do so, follow these steps:

1. Create a service account to access shared cache in [the `gitlab-qa-resources` GCP project](https://console.cloud.google.com/iam-admin/serviceaccounts?project=gitlab-qa-resources).
   1. Download the service account credentials JSON file.
1. Create a VM instance to host the auto-scaled runners manager in [the `gitlab-qa-resources` GCP project](https://console.cloud.google.com/compute/instances?project=gitlab-qa-resources).
   1. Add the service account to the VM instance.
   1. Add you SSH key to the VM instance.
   1. Upload the service account credentials JSON file to the VM instance (e.g. `scp ~/Downloads/gitlab-qa-resources-abc123.json <your-username>@VM-IP:/home/<your-username>`).
1. Create a storage bucket for the shared cache in [the `gitlab-qa-resources` GCP project](https://console.cloud.google.com/storage/browser?project=gitlab-qa-resources).
1. SSH into the VM instance (using GCP's Web interface).
1. Follow [the installation steps for auto-scaled runners manager](https://docs.gitlab.com/runner/executors/docker_machine.html#preparing-the-environment):
   1. [Install `gitlab-runner`](https://docs.gitlab.com/runner/install/linux-repository.html#installing-gitlab-runner).
   1. [Install Docker Machine](https://web.archive.org/web/20210619101324/https://docs.docker.com/machine/install-machine/).
   1. [Register the runner](https://docs.gitlab.com/runner/register/#linux)
      1. Make sure to set a specific tag for the runner.
      1. Set `docker+machine` as the runner executor.
   1. Move the service account credentials JSON file to its final destination (using `sudo`): `sudo mv home/<your-username>/gitlab-qa-resources-abc123.json /etc/gitlab-runner/service-account.json`
   1. Edit the runner manager with something like the following configuration (make sure to check the [`[runners.machine]`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnersmachine-section) documentation):

   ```toml
   concurrent = 500
   check_interval = 0

   [session_server]
     session_timeout = 1800

   [[runners]]
     name = "n2d-highcpu-4 Relevant description of the runner manager"
     url = "https://gitlab.com/"
     token = "[REDACTED]"
     executor = "docker+machine"
     limit = 500
     pre_clone_script = "eval \"$CI_PRE_CLONE_SCRIPT\""
     request_concurrency = 500
     environment = [
       "DOCKER_TLS_CERTDIR=",
       "DOCKER_DRIVER=overlay2",
       "FF_USE_DIRECT_DOWNLOAD=true",
       "FF_GITLAB_REGISTRY_HELPER_IMAGE=true"
     ]

     [runners.custom_build_dir]
       enabled = true

     [runners.cache]
       Type = "gcs"
       Shared = true
       [runners.cache.gcs]
         BucketName = "BUCKET-NAME-FOR-THE-SHARED-CACHE"
         CredentialsFile = "/etc/gitlab-runner/service-account.json"

     [runners.docker]
       tls_verify = false
       image = "ruby:2.7"
       privileged = true
       disable_entrypoint_overwrite = false
       oom_kill_disable = false
       disable_cache = false
       shm_size = 0
       volumes = [
         "/cache",
         "/certs/client"
       ]

     [runners.machine]
       IdleCount = 0
       IdleTime = 600
       MachineDriver = "google"
       MachineName = "rymai-n2d-hc-4-%s"
       MachineOptions = [
         # Additional machine options can be added using the Google Compute Engine driver.
         # If you experience problems with an unreachable host (ex. "Waiting for SSH"),
         # you should remove optional parameters to help with debugging.
         # https://docs.docker.com/machine/drivers/gce/
         "google-project=gitlab-qa-resources",
         "google-zone=us-central1-a", # e.g. 'us-central1-a', full list in https://cloud.google.com/compute/docs/regions-zones/
         "google-machine-type=n2d-highcpu-4", # e.g. 'n1-standard-8'
         "google-disk-size=50",
         "google-disk-type=pd-ssd",
         "google-label=gl_resource_type:ci_ephemeral",
         "google-username=cos",
         "google-operation-backoff-initial-interval=2",
         "google-use-internal-ip",
         "engine-registry-mirror=https://mirror.gcr.io",
       ]
       OffPeakTimezone = ""
       OffPeakIdleCount = 0
       OffPeakIdleTime = 0
       MaxBuilds = 20

       [[runners.machine.autoscaling]]
         Periods = ["* * 8-18 * * mon-fri *"] # During the weekends
         IdleCount = 0
         IdleTime = 600
         Timezone = "UTC"
   ```

## Scripts and tools for automating tasks

### Toolbox

The [Quality Toolbox](https://gitlab.com/gitlab-org/quality/toolbox) contains several scripts that can be useful when working with GitLab end-to-end tests, such as one to [generate a report of flaky tests](https://gitlab.com/gitlab-org/quality/toolbox#generate-a-flaky-examples-report), or one to [report job success rates](https://gitlab.com/gitlab-org/quality/toolbox#pipeline-job-report).

### Rake tasks

The [`qa/tools` directory](https://gitlab.com/gitlab-org/gitlab/blob/master/qa/qa/tools/) contains Rake tasks that perform automated tasks on a schedule (such as [deleting subgroups](https://gitlab.com/gitlab-org/gitlab/-/blob/master/qa/qa/tools/delete_subgroups.rb) after a test run), or that can be run as needed (such as [revoking personal access tokens](https://gitlab.com/gitlab-org/gitlab/-/blob/master/qa/qa/tools/revoke_all_personal_access_tokens.rb)).

#### Delete Test SSH Keys

This script deletes SSH keys for a specific user. It can be executed via the `delete_test_ssh_keys` Rake task in the `qa` directory.

The Rake task accepts three arguments that can be used to limit the keys that are deleted, and to perform a dry run.

- The first argument, `title_portion`, limits keys to be deleted to those that include the string provided.
- The second argument, `delete_before`, limits keys to be deleted to those that were created before the given date.
- The third optional argument, `dry_run`, determines if the command will be executed as a dry run, summarizing the keys to be deleted. Set to `true` to execute as a dry run.

Two environment variables are also required:

- `GITLAB_ADDRESS` is the address of the target GitLab instance.
- `GITLAB_QA_ACCESS_TOKEN` should be a personal access token with API access and should belong to the user whose keys will be deleted.

For example, the following command will delete all SSH keys with a title that includes `E2E test key:` and that were created before `2020-08-02` on `https://staging.gitlab.com` for the user with the provided personal access token:

```shell
GITLAB_QA_ACCESS_TOKEN=secret GITLAB_ADDRESS=https://staging.gitlab.com bundle exec rake "delete_test_ssh_keys[E2E test key:, 2020-08-02]"
```

#### Set default password and create a personal access token

There is a Rake task to set the default password (from `Runtime::User.default_password`) if it's not set already, and it creates a personal access token.

This is useful when testing on a fresh GitLab instance (e.g., an omnibus-GitLab Docker image) and you don't want to have to log in and create an access token manually.

Usage example (run from the `gitlab/qa` directory):

```shell
$ bundle exec rake  'initialize_gitlab_auth[https://gitlab.test]'
Signing in and creating the default password for the root user if it's not set already...
Creating an API scoped access token for the root user...
Token: <some_token_value>
```
