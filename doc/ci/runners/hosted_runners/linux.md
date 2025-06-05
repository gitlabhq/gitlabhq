---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Hosted runners on Linux
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

Hosted runners on Linux for GitLab.com run on Google Cloud Compute Engine. Each job gets a fully isolated, ephemeral virtual machine (VM). The default region is `us-east1`.

Each VM uses the Google Container-Optimized OS (COS) and the latest version of Docker Engine running the `docker+machine`
[executor](https://docs.gitlab.com/runner/executors/#docker-machine-executor).
The machine type and underlying processor type might change. Jobs optimized for a specific processor design might behave inconsistently.

[Untagged](../../yaml/_index.md#tags) jobs run on the `small` Linux x86-64 runner.

## Machine types available for Linux - x86-64

GitLab offers the following machine types for hosted runners on Linux x86-64.

<table id="x86-runner-specs" aria-label="Machine types available for Linux x86-64">
  <thead>
    <tr>
      <th>Runner Tag</th>
      <th>vCPUs</th>
      <th>Memory</th>
      <th>Storage</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-small-amd64</code> (default)
      </td>
      <td class="vcpus">2</td>
      <td>8 GB</td>
      <td>30 GB</td>
    </tr>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-medium-amd64</code>
      </td>
      <td class="vcpus">4</td>
      <td>16 GB</td>
      <td>50 GB</td>
    </tr>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-large-amd64</code> (Premium and Ultimate only)
      </td>
      <td class="vcpus">8</td>
      <td>32 GB</td>
      <td>100 GB</td>
    </tr>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-xlarge-amd64</code> (Premium and Ultimate only)
      </td>
      <td class="vcpus">16</td>
      <td>64 GB</td>
      <td>200 GB</td>
    </tr>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-2xlarge-amd64</code> (Premium and Ultimate only)
      </td>
      <td class="vcpus">32</td>
      <td>128 GB</td>
      <td>200 GB</td>
    </tr>
  </tbody>
</table>

## Machine types available for Linux - Arm64

GitLab offers the following machine type for hosted runners on Linux Arm64.

<table id="arm64-runner-specs" aria-label="Machine types available for Linux Arm64">
  <thead>
    <tr>
      <th>Runner Tag</th>
      <th>vCPUs</th>
      <th>Memory</th>
      <th>Storage</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-small-arm64</code>
      </td>
      <td class="vcpus">2</td>
      <td>8 GB</td>
      <td>30 GB</td>
    </tr>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-medium-arm64</code> (Premium and Ultimate only)
      </td>
      <td class="vcpus">4</td>
      <td>16 GB</td>
      <td>50 GB</td>
    </tr>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-large-arm64</code> (Premium and Ultimate only)
      </td>
      <td class="vcpus">8</td>
      <td>32 GB</td>
      <td>100 GB</td>
    </tr>
  </tbody>
</table>

{{< alert type="note" >}}

Users can experience network connectivity issues when they use Docker-in-Docker with hosted runners on Linux
Arm. This issue occurs when the maximum transmission unit (MTU) value in Google Cloud and Docker don't match.
To resolve this issue, set `--mtu=1400` in the client side Docker configuration.
For more details, see [issue 473739](https://gitlab.com/gitlab-org/gitlab/-/issues/473739#workaround).

{{< /alert >}}

## Container images

As runners on Linux are using the `docker+machine` [executor](https://docs.gitlab.com/runner/executors/#docker-machine-executor),
you can choose any container image by defining the [`image`](../../yaml/_index.md#image) in your `.gitlab-ci.yml` file.
Ensure your selected Docker image is compatible with your processor architecture.

If no image is set, the default is `ruby:3.1`.

## Docker-in-Docker support

Runners with any of the `saas-linux-<size>-<architecture>` tags are configured to run in `privileged` mode
to support [Docker-in-Docker](../../docker/using_docker_build.md#use-docker-in-docker).
With these runners, you can build Docker images natively or run multiple containers in your isolated job.

Runners with the `gitlab-org` tag do not run in `privileged` mode and cannot be used for Docker-in-Docker builds.

## Example `.gitlab-ci.yml` file

To use a machine type other than `small`, add a `tags:` keyword to your job.
For example:

```yaml
job_small:
  script:
    - echo "This job is untagged and runs on the default small Linux x86-64 instance"

job_medium:
  tags:
    - saas-linux-medium-amd64
  script:
    - echo "This job runs on the medium Linux x86-64 instance"

job_large:
  tags:
    - saas-linux-large-arm64
  script:
    - echo "This job runs on the large Linux Arm64 instance"
```
