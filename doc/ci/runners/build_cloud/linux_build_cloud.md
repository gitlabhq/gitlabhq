---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Linux shared runners

Linux shared runners on GitLab.com run in autoscale mode and are powered by Google Cloud Platform.

Autoscaling means reduced queue times to spin up CI/CD jobs, and isolated VMs for each job, thus maximizing security. These shared runners are available for users and customers on GitLab.com.

GitLab offers Ultimate tier capabilities and included CI/CD minutes per group per month for our [Open Source](https://about.gitlab.com/solutions/open-source/join/), [Education](https://about.gitlab.com/solutions/education/), and [Startups](https://about.gitlab.com/solutions/startups/) programs. For private projects, GitLab offers various [plans](https://about.gitlab.com/pricing/), starting with a Free tier.

All your CI/CD jobs run on [n1-standard-1 instances](https://cloud.google.com/compute/docs/machine-types) with 3.75GB of RAM, CoreOS and the latest Docker Engine
installed. Instances provide 1 vCPU and 25GB of HDD disk space. The default
region of the VMs is US East1.
Each instance is used only for one job, this ensures any sensitive data left on the system can't be accessed by other people their CI jobs.

The `gitlab-shared-runners-manager-X.gitlab.com` fleet of runners are dedicated for GitLab projects as well as community forks of them. They use a slightly larger machine type (n1-standard-2) and have a bigger SSD disk size. They don't run untagged jobs and unlike the general fleet of shared runners, the instances are re-used up to 40 times.

Jobs handled by the shared runners on GitLab.com (`shared-runners-manager-X.gitlab.com`),
**time out after 3 hours**, regardless of the timeout configured in a
project. Check the issues [4010](https://gitlab.com/gitlab-com/infrastructure/-/issues/4010) and [4070](https://gitlab.com/gitlab-com/infrastructure/-/issues/4070) for the reference.

Below are the shared runners settings.

| Setting                               | GitLab.com                                        | Default    |
| -----------                           | -----------------                                 | ---------- |
| Executor                              | `docker+machine`                                  | -          |
| Default Docker image                  | `ruby:2.5`                                        | -          |
| `privileged` (run [Docker in Docker](https://hub.docker.com/_/docker/)) | `true`          | `false`    |

## Pre-clone script

Linux shared runners on GitLab.com provide a way to run commands in a CI
job before the runner attempts to run `git init` and `git fetch` to
download a GitLab repository. The
[`pre_clone_script`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section)
can be used for:

- Seeding the build directory with repository data
- Sending a request to a server
- Downloading assets from a CDN
- Any other commands that must run before the `git init`

To use this feature, define a [CI/CD variable](../../../ci/variables/index.md#custom-cicd-variables) called
`CI_PRE_CLONE_SCRIPT` that contains a bash script.

[This example](../../../development/pipelines.md#pre-clone-step)
demonstrates how you might use a pre-clone step to seed the build
directory.

NOTE:
The `CI_PRE_CLONE_SCRIPT` variable does not work on Windows runners.

## `config.toml`

The full contents of our `config.toml` are:

NOTE:
Settings that are not public are shown as `X`.

**Google Cloud Platform**

```toml
concurrent = X
check_interval = 1
metrics_server = "X"
sentry_dsn = "X"

[[runners]]
  name = "docker-auto-scale"
  request_concurrency = X
  url = "https://gitlab.com/"
  token = "SHARED_RUNNER_TOKEN"
  pre_clone_script = "eval \"$CI_PRE_CLONE_SCRIPT\""
  executor = "docker+machine"
  environment = [
    "DOCKER_DRIVER=overlay2",
    "DOCKER_TLS_CERTDIR="
  ]
  limit = X
  [runners.docker]
    image = "ruby:2.5"
    privileged = true
    volumes = [
      "/certs/client",
      "/dummy-sys-class-dmi-id:/sys/class/dmi/id:ro" # Make kaniko builds work on GCP.
    ]
  [runners.machine]
    IdleCount = 50
    IdleTime = 3600
    MaxBuilds = 1 # For security reasons we delete the VM after job has finished so it's not reused.
    MachineName = "srm-%s"
    MachineDriver = "google"
    MachineOptions = [
      "google-project=PROJECT",
      "google-disk-size=25",
      "google-machine-type=n1-standard-1",
      "google-username=core",
      "google-tags=gitlab-com,srm",
      "google-use-internal-ip",
      "google-zone=us-east1-d",
      "engine-opt=mtu=1460", # Set MTU for container interface, for more information check https://gitlab.com/gitlab-org/gitlab-runner/-/issues/3214#note_82892928
      "google-machine-image=PROJECT/global/images/IMAGE",
      "engine-opt=ipv6", # This will create IPv6 interfaces in the containers.
      "engine-opt=fixed-cidr-v6=fc00::/7",
      "google-operation-backoff-initial-interval=2" # Custom flag from forked docker-machine, for more information check https://github.com/docker/machine/pull/4600
    ]
    [[runners.machine.autoscaling]]
      Periods = ["* * * * * sat,sun *"]
      Timezone = "UTC"
      IdleCount = 70
      IdleTime = 3600
    [[runners.machine.autoscaling]]
      Periods = ["* 30-59 3 * * * *", "* 0-30 4 * * * *"]
      Timezone = "UTC"
      IdleCount = 700
      IdleTime = 3600
  [runners.cache]
    Type = "gcs"
    Shared = true
    [runners.cache.gcs]
      CredentialsFile = "/path/to/file"
      BucketName = "bucket-name"
```
