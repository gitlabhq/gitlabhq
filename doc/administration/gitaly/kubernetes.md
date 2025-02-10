---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Gitaly on Kubernetes
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated
**Status:** Experiment

Running Gitaly on Kubernetes has availability trade-offs, so consider these trade-offs when planing a production environment and set expectations accordingly.
This document describes and provides guidance on how to minimize, and plan for existing limitations.

Gitaly Cluster (Praefect) is unsupported. For more information on running Gitaly on Kubernetes, see [epic 6127](https://gitlab.com/groups/gitlab-org/-/epics/6127).

## Context

By design, Gitaly (non-Cluster) is a single point of failure service (SPoF). Data is sourced and served from a single instance.
For Kubernetes, when the StatefulSet pod rotates (for example, during upgrades, node maintenance, or eviction), the rotation causes service disruption for data served by the pod or instance.

In a [Cloud Native Hybrid](../reference_architectures/1k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts) setup (Gitaly VM), the Linux package (Omnibus)
masks the problem by:

1. Upgrading the Gitaly binary in-place.
1. Performing a graceful reload.

The same approach doesn't fit a container-based lifecycle where a container or pod needs to fully shutdown and start as a new container or pod.

Gitaly Cluster (Praefect) solves the data and service high-availability aspect by replicating data across instances. However, Gitaly Cluster is unsuited to run in Kubernetes
because of [existing issues and design constraints](_index.md#known-issues) that are augmented by a container-based platform.

To support a Cloud Native deployment, Gitaly (non-Cluster) is the only option.
By leveraging the right Kubernetes and Gitaly features and configuration, you can minimize service disruption and provide a good user experience.

## Requirements

The information on this page assumes:

- Kubernetes version equal to or greater than `1.29`.
- Kubernetes node `runc` version equal to or greater than `1.1.9`.
- Kubernetes node cgroup v2. Native, hybrid v1 mode is not supported. Only
  [`systemd`-style cgroup structure](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#systemd-cgroup-driver) is supported (Kubernetes default).
- Pod access to node mountpoint `/sys/fs/cgroup`.
- Pod init container (`init-cgroups`) access to `root` user filesystem permissions on `/sys/fs/cgroup`. Used to delegate the pod cgroup to the Gitaly container
  (user `git`, UID `1000`).

## Guidance

When running Gitaly in Kubernetes, you must:

- [Address pod disruption](#address-pod-disruption).
- [Address resource contention and saturation](#address-resource-contention-and-saturation).
- [Optimize pod rotation time](#optimize-pod-rotation-time).

### Address pod disruption

A pod can rotate for many reasons. Understanding and planing the service lifecycle helps minimize disruption.

For example, with Gitaly, a Kubernetes `StatefulSet` rotates on `spec.template` object changes, which can happen during Helm Chart upgrades (labels, or image tag) or pod resource requests or limits updates.

This section focuses on common pod disruption cases and how to address them.

#### Schedule maintenance windows

Because the service is not highly available, certain operations can cause brief service outages. Scheduling maintenance windows signals potential
service disruption and helps set expectations. You should use maintenance windows for:

- GitLab Helm chart upgrades and reconfiguration.
- Gitaly configuration changes.
- Kubernetes node maintenance windows. For example, upgrades and patching. Isolating Gitaly into its own dedicated node pool might help.

#### Use `PriorityClass`

Use [PriorityClass](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/#priorityclass) to assign Gitaly pods higher priority compared to other pods, to help with node saturation pressure, eviction priority, and scheduling latency:

1. Create a priority class:

   ```yaml
   apiVersion: scheduling.k8s.io/v1
   kind: PriorityClass
   metadata:
     name: gitlab-gitaly
   value: 1000000
   globalDefault: false
   description: "GitLab Gitaly priority class"
   ```

1. Assign the priority class to Gitaly pods:

   ```yaml
   gitlab:
     gitaly:
       priorityClassName: gitlab-gitaly
   ```

#### Signal node autoscaling to prevent eviction

Node autoscaling tooling adds and removes Kubernetes nodes as needed to schedule pods and optimize cost.

During downscaling events, the Gitaly pod can be evicted to optimize resource usage. Annotations are usually available to control this behavior and
exclude workloads. For example, with Cluster Autoscaler:

```yaml
gitlab:
  gitaly:
    annotations:
      cluster-autoscaler.kubernetes.io/safe-to-evict: "false"
```

### Address resource contention and saturation

Gitaly service resource usage can be unpredictable because of the indeterminable nature of Git operations. Not all repositories are the same and size
heavily influences performance and resource usage, especially for [monorepos](../../user/project/repository/monorepos/_index.md).

In Kubernetes, uncontrolled resource usage can lead to Out Of Memory (OOM) events, which forces the platform to terminate the pod and kill all its processes.
Pod termination raises two important concerns:

- Data/Repository corruption
- Service disruption

This section focuses on reducing the scope of impact and protecting the service as a whole.

#### Constrain Git processes resource usage

Isolating Git processes provides safety in guaranteeing that a single Git call can't consume all service and pod resources.

Gitaly can use Linux [Control Groups (cgroups)](configure_gitaly.md#control-groups) to impose smaller, per repository quotas on resource usage.

You should maintain cgroup quotas below the overall pod resource allocation.
CPU is not critical because it only slows down the service. However, memory saturation can lead to pod termination. A 1 GiB memory buffer between pod request and Git cgroup
allocation is a safe starting point. Sizing the buffer depends on traffic patterns and repository data.

For example, with a pod memory request of 15 GiB, 14 GiB is allocated to Git calls:

```yaml
gitlab:
  gitaly:
    cgroups:
      enabled: true
      # Total limit across all repository cgroups, excludes Gitaly process
      memoryBytes: 15032385536 # 14GiB
      cpuShares: 1024
      cpuQuotaUs: 400000 # 4 cores
      # Per repository limits, 50 repository cgroups
      repositories:
        count: 50
        memoryBytes: 7516192768 # 7GiB
        cpuShares: 512
        cpuQuotaUs: 200000 # 2 cores
```

For more information, see [Gitaly configuration documentation](configure_gitaly.md#control-groups).

#### Right size Pod resources

Sizing the Gitaly pod is critical and [reference architectures](../reference_architectures/_index.md#cloud-native-hybrid) provide some guidance as a starting
point. However, different repositories and usage patterns consume varying degrees of resources.
You should monitor resource usage and adjust accordingly over time.

Memory is the most sensitive resource in Kubernetes because running out of memory can trigger pod termination.
[Isolating Git calls with cgroups](#constrain-git-processes-resource-usage) helps to restrict resource usage for repository operations, but that doesn't include the Gitaly service itself.
In line with the previous recommendation on cgroup quotas, add a buffer between overall Git cgroup memory allocation and pod memory request to improve safety.

A pod `Guaranteed` [Quality of Service](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/) class is preferred
(resource requests match limits). With this setting, the pod is less susceptible to resource contention and is guaranteed to never be evicted based on consumption from other pods.

Example resource configuration:

```yaml
gitlab:
  gitaly:
    resources:
      requests:
        cpu: 4000m
        memory: 15Gi
      limits:
        cpu: 4000m
        memory: 15Gi

    init:
      resources:
        requests:
          cpu: 50m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 32Mi
```

#### Configure concurrency rate limiting

As well as using cgroups, you can use concurrency limits to further help protect the service from abnormal traffic patterns. For more information, see
[concurrency configuration documentation](concurrency_limiting.md) and [how to monitor limits](monitoring.md#monitor-gitaly-concurrency-limiting).

#### Isolate Gitaly pods

When running multiple Gitaly pods, you should schedule them in different nodes to spread out the failure domain. This can be enforced using pod anti affinity.
For example:

```yaml
gitlab:
  gitaly:
    antiAffinity: hard
```

### Optimize pod rotation time

This section covers areas of optimization to reduce downtime during maintenance events or unplanned infrastructure events by reducing the time it takes the pod to start serving traffic.

#### Persistent Volume permissions

As the size of data grows (Git history and more repositories), the pod takes more and more time to start and become ready.

During pod initialization, as part of the persistent volume mount, the file system permissions and ownership are explicitly set to the container `uid` and `gid`.
This operation runs by default and can significantly slow down pod startup time because the stored Git data contains many small files.

This behavior is configurable with the
[`fsGroupChangePolicy`](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#configure-volume-permission-and-ownership-change-policy-for-pods)
attribute. Use this attribute to perform the operation only if the volume root `uid` or `gid` mismatches the container spec:

```yaml
gitlab:
  gitaly:
    securityContext:
      fsGroupChangePolicy: OnRootMismatch
```

#### Health probes

The Gitaly pod starts serving traffic after the readiness probe succeeds. The default probe times are conservative to cover most use cases.
Reducing the `readinessProbe` `initialDelaySeconds` attribute triggers probes earlier, which accelerates pod readiness. For example:

```yaml
gitlab:
  gitaly:
    statefulset:
      readinessProbe:
        initialDelaySeconds: 2
        periodSeconds: 10
        timeoutSeconds: 3
        successThreshold: 1
        failureThreshold: 3
```

#### Gitaly graceful shutdown timeout

By default, when terminating, Gitaly grants a 1 minute timeout for in-flight requests to complete.
While beneficial at first glance, this timeout:

- Slows down pod rotation.
- Reduces availability by rejecting requests during the shutdown process.

A better approach in a container-based deployment is to rely on client-side retry logic. You can reconfigure the timeout by using the `gracefulRestartTimeout` field.
For example, to grant a 1 second graceful timeout:

```yaml
gitlab:
  gitaly:
    gracefulRestartTimeout: 1
```
