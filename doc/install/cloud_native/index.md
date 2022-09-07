---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
comments: false
description: Install a cloud-native version of GitLab
type: index
---

# Cloud-native GitLab **(FREE SELF)**

A [cloud-native](https://gitlab.com/gitlab-org/build/CNG) version of GitLab is
available for deployment on Kubernetes, OpenShift, and Kubernetes-compatible
platforms. The following deployment methods are available:

- [GitLab Helm chart](https://docs.gitlab.com/charts/): A cloud-native version of GitLab
  and all of its components. Use this installation method if your infrastructure is built
  on Kubernetes and you're familiar with how it works. This method of deployment has different
  management, observability, and concepts than traditional deployments.
- [GitLab Operator](https://docs.gitlab.com/operator/): An installation and management method
  that follows the
  [Kubernetes Operator pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/).
  Use the GitLab Operator to run GitLab in an
  [OpenShift](../openshift_and_gitlab/index.md) or another Kubernetes-compatible platform.
