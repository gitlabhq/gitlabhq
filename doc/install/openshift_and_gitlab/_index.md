---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: OpenShift support
---

OpenShift - GitLab compatibility can be addressed in three different aspects. This page helps navigating between these aspects and provides introductory information for getting started with OpenShift and GitLab.

## What is OpenShift

OpenShift helps you to develop, deploy, and manage container-based applications. It provides you with a self-service platform to create, modify, and deploy applications on demand, thus enabling faster development and release lifecycles.

## Use OpenShift to run GitLab Self-Managed

You can run GitLab in an OpenShift cluster with the GitLab Operator. For more information about
setting up GitLab on OpenShift, see [GitLab Operator](https://docs.gitlab.com/operator/).

## Use OpenShift to run a GitLab Runner Fleet

The GitLab Operator does not include the GitLab Runner. To install and manage a GitLab Runner fleet in an OpenShift cluster, use the
[GitLab Runner Operator](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator).

### Deploy to and integrate with OpenShift from GitLab

Deploying custom or COTS applications on top of OpenShift from GitLab is supported using [the GitLab agent](../../user/clusters/agent/_index.md).

### Unsupported GitLab features

#### Docker-in-Docker

When using OpenShift to run a GitLab Runner Fleet, we do not support some GitLab features given OpenShift's security model.
Features requiring Docker-in-Docker might not work.

For Auto DevOps, the following features are not supported yet:

- [Auto Code Quality](../../ci/testing/code_quality.md)
- [License approval policies](../../user/compliance/license_approval_policies.md)
- Auto Browser Performance Testing
- Auto Build
- [Operational Container Scanning](../../user/clusters/agent/vulnerabilities.md) (Note: Pipeline [Container Scanning](../../user/application_security/container_scanning/_index.md) is supported)

For Auto Build, there's a [possible workaround using `kaniko`](../../ci/docker/using_kaniko.md).
You can check the progress of the implementation in this [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/332560).
