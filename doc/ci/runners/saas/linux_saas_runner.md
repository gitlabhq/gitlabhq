---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# SaaS runners on Linux **(FREE SAAS)**

SaaS runners on Linux are autoscaled ephemeral Google Cloud Platform virtual machines.

Autoscaling means reduced queue times to spin up CI/CD jobs, and isolated VMs for each job, thus maximizing security. These shared runners are available on GitLab.com.

GitLab offers Ultimate tier capabilities and included CI/CD minutes per group per month for our [Open Source](https://about.gitlab.com/solutions/open-source/join/), [Education](https://about.gitlab.com/solutions/education/), and [Startups](https://about.gitlab.com/solutions/startups/) programs. For private projects, GitLab offers various [plans](https://about.gitlab.com/pricing/), starting with a Free tier.

All your CI/CD jobs run on [n1-standard-1 instances](https://cloud.google.com/compute/docs/machine-types) with 3.75GB of RAM, Google COS and the latest Docker Engine
installed. Instances provide 1 vCPU and 25GB of HDD disk space. The default
region of the VMs is US East1.
Each instance is used only for one job. This ensures that any sensitive data left on the system can't be accessed by other people's CI/CD jobs.

NOTE:
The final disk space your jobs can use will be less than 25GB. Some disk space allocated to the instance will be occupied by the operating system, the Docker image, and a copy of your cloned repository.  

The `gitlab-shared-runners-manager-X.gitlab.com` fleet of runners are dedicated for GitLab projects as well as community forks of them. They use a slightly larger machine type (n1-standard-2) and have a bigger SSD disk size. They don't run untagged jobs and unlike the general fleet of shared runners, the instances are re-used up to 40 times.

Jobs handled by shared runners on GitLab.com (`shared-runners-manager-X.gitlab.com`)
**time out after 3 hours**, regardless of the timeout configured in a
project. Check issue [#4010](https://gitlab.com/gitlab-com/infrastructure/-/issues/4010) and [#4070](https://gitlab.com/gitlab-com/infrastructure/-/issues/4070) for the reference.

Jobs handled by shared runners on Windows and macOS on GitLab.com **time out after 1 hour** while this service is in the [Beta](../../../policy/alpha-beta-support.md#beta-features) stage.

Below are the runners' settings.

| Setting                               | GitLab.com                                        | Default    |
| -----------                           | -----------------                                 | ---------- |
| Executor                              | `docker+machine`                                  | -          |
| Default Docker image                  | `ruby:2.5`                                        | -          |
| `privileged` (run [Docker in Docker](https://hub.docker.com/_/docker/)) | `true`          | `false`    |

These runners share a [distributed cache](https://docs.gitlab.com/runner/configuration/autoscale.html#distributed-runners-caching) through use of a Google Cloud Storage (GCS) bucket. Cache contents not updated within the last 14 days are automatically removed through use of an [object lifecycle management policy](https://cloud.google.com/storage/docs/lifecycle).

## Pre-clone script

With SaaS runners on Linux, you can run commands in a CI
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

NOTE:
The `CI_PRE_CLONE_SCRIPT` variable does not work on Windows runners.

### Pre-clone script example

This example was used in the `gitlab-org/gitlab` project until November 2021.
The project no longer uses this optimization because the [pack-objects cache](../../../administration/gitaly/configure_gitaly.md#pack-objects-cache)
lets Gitaly serve the full CI/CD fetch traffic. See [Git fetch caching](../../../development/pipelines.md#git-fetch-caching).

The `CI_PRE_CLONE_SCRIPT` was defined as a project CI/CD variable:

```shell
(
  echo "Downloading archived master..."
  wget -O /tmp/gitlab.tar.gz https://storage.googleapis.com/gitlab-ci-git-repo-cache/project-278964/gitlab-master-shallow.tar.gz

  if [ ! -f /tmp/gitlab.tar.gz ]; then
      echo "Repository cache not available, cloning a new directory..."
      exit
  fi

  rm -rf $CI_PROJECT_DIR
  echo "Extracting tarball into $CI_PROJECT_DIR..."
  mkdir -p $CI_PROJECT_DIR
  cd $CI_PROJECT_DIR
  tar xzf /tmp/gitlab.tar.gz
  rm -f /tmp/gitlab.tar.gz
  chmod a+w $CI_PROJECT_DIR
)
```

The first step of the script downloads `gitlab-master.tar.gz` from Google Cloud Storage.
There was a [GitLab CI/CD job named `cache-repo`](https://gitlab.com/gitlab-org/gitlab/-/blob/5fb40526c8c8aaafc5f92eab36d5bbddaca3893d/.gitlab/ci/cache-repo.gitlab-ci.yml)
that was responsible for keeping that archive up-to-date. Every two hours on a scheduled pipeline,
it did the following:

1. Create a fresh clone of the `gitlab-org/gitlab` repository on GitLab.com.
1. Save the data as a `.tar.gz`.
1. Upload it into the Google Cloud Storage bucket.

When a job ran with this configuration, the output looked similar to:

```shell
$ eval "$CI_PRE_CLONE_SCRIPT"
Downloading archived master...
Extracting tarball into /builds/gitlab-org/gitlab...
Fetching changes...
Reinitialized existing Git repository in /builds/gitlab-org/gitlab/.git/
```

The `Reinitialized existing Git repository` message shows that
the pre-clone step worked. The runner runs `git init`, which
overwrites the Git configuration with the appropriate settings to fetch
from the GitLab repository.

`CI_REPO_CACHE_CREDENTIALS` must contain the Google Cloud service account
JSON for uploading to the `gitlab-ci-git-repo-cache` bucket.

Note that this bucket should be located in the same continent as the
runner, or [you can incur network egress charges](https://cloud.google.com/storage/pricing).

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
