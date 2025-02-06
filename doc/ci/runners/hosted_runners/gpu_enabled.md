---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GPU-enabled hosted runners
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com

GitLab provides GPU-enabled hosted runners to accelerate heavy compute workloads for ModelOps
or HPC such as the training or deployment of Large Language Models (LLMs) as part of ModelOps workloads.

GitLab provides GPU-enabled runners only on Linux. For more information about how these runners work, see [Hosted runners on Linux](../hosted_runners/linux.md)

## Machine types available for GPU-enabled runners

The following machine types are available for GPU-enabled runners on Linux x86-64.

| Runner Tag                             | vCPUs | Memory | Storage | GPU                            | GPU Memory |
|----------------------------------------|-------|--------|---------|--------------------------------|------------|
| `saas-linux-medium-amd64-gpu-standard` | 4     | 15 GB  | 50 GB   | 1 Nvidia Tesla T4 (or similar) | 16 GB      |

## Container images with GPU drivers

As with GitLab hosted runners on Linux, your job runs in an isolated virtual machine (VM)
with a bring-your-own-image policy. GitLab mounts the GPU from the host VM into
your isolated environment. To use the GPU, you must use a Docker image with the
GPU driver installed. For Nvidia GPUs, you can use their [CUDA Toolkit](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/cuda).

## Example `.gitlab-ci.yml` file

In the following example of the `.gitlab-ci.yml` file, the Nvidia CUDA base Ubuntu image is used.
In the `script:` section, you install Python.

```yaml
gpu-job:
  stage: build
  tags:
    - saas-linux-medium-amd64-gpu-standard
  image: nvcr.io/nvidia/cuda:12.1.1-base-ubuntu22.04
  script:
    - apt-get update
    - apt-get install -y python3.10
    - python3.10 --version
```

If you don't want to install larger libraries such as Tensorflow or XGBoost each time you run a job, you can create your own image with all the required components pre-installed.
Watch this demo to learn how to leverage GPU-enabled hosted runners to train an XGBoost model:
<div class="video-fallback">
  Video demonstration of GitLab GPU-enabled hosted runners: <a href="https://youtu.be/tElegG4NCZ0">Train XGboost models with GitLab</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/tElegG4NCZ0" frameborder="0" allowfullscreen> </iframe>
</figure>
