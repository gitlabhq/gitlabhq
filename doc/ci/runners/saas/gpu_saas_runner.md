---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GPU-enabled SaaS runners **(PREMIUM SAAS)**

GitLab provides GPU-enabled SaaS runners to accelerate heavy compute workloads for ModelOps
or HPC such as the training or deployment of Large Language Models (LLMs) as part of ModelOps workloads.

GitLab provides GPU-enabled runners only on Linux. For more information about how these runners work, see [SaaS runners on Linux](../saas/linux_saas_runner.md)

## Machine types available for GPU-enabled runners

The following machine types are available for GPU-enabled runners on Linux x86-64.

| Runner Tag                             | vCPUs | Memory | Storage | GPU                            |
|----------------------------------------|-------|--------|---------|--------------------------------|
| `saas-linux-medium-amd64-gpu-standard` | 4     | 16 GB  | 50 GB   | 1 Nvidia Tesla T4 (or similar) |

## Container images with GPU drivers

As with GitLab SaaS runners on Linux, your job runs in an isolated virtual machine (VM)
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
