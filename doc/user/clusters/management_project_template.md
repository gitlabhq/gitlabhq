---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Cluster Management Project Template **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25318) in GitLab 12.10 with Helmfile support via Helm v2.
> - [Improved](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63577) in GitLab 14.0 with Helmfile support via Helm v3 instead, and a much more flexible usage of Helmfile. This introduces breaking changes that are detailed below.

This [GitLab built-in project template](../project/working_with_projects.md#built-in-templates)
provides a quicker start for users interested in managing cluster
applications via [Helm v3](https://helm.sh/) charts. More specifically, taking advantage of the
[Helmfile](https://github.com/roboll/helmfile) utility client. The template consists of some pre-configured apps that
should help you get started quickly using various GitLab features. Still, you have all the flexibility to remove the ones you do not
need, or even add new ones that are not built-in.

## How to use this template

1. Create a new project, choosing "GitLab Cluster Management" from the list of [built-in project templates](../project/working_with_projects.md#built-in-templates).
1. Make this project a [cluster management project](management_project.md).
1. If you used the [GitLab Managed Apps](applications.md), refer to
   [Migrating from GitLab Managed Apps](migrating_from_gma_to_project_template.md).

### Components

In the repository of the newly-created project, you will find:

- A predefined [`.gitlab-ci.yml`](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/blob/master/.gitlab-ci.yml)
  file, with a CI pipeline already configured.
- A main [`helmfile.yaml`](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/blob/master/helmfile.yaml) to toggle which applications you would like to manage.
- An `applications` directory with a `helmfile.yaml` configured for each application GitLab provides.

#### The `.gitlab-ci.yml` file

The base image used in your pipeline is built by the [cluster-applications](https://gitlab.com/gitlab-org/cluster-integration/cluster-applications)
project. This image consists of a set of Bash utility scripts to support [Helm v3 releases](https://helm.sh/docs/intro/using_helm/#three-big-concepts):

- `gl-fail-if-helm2-releases-exist {namespace}`: It tries to detect whether you have apps deployed through Helm v2
  releases for a given namespace. If so, it will fail the pipeline and ask you to manually
  [migrate your Helm v2 releases to Helm v3](https://helm.sh/docs/topics/v2_v3_migration/).
- `gl-ensure-namespace {namespace}`: It creates the given namespace if it does not exist and adds the necessary label
  for the [Cilium](https://github.com/cilium/cilium/) app network policies to work.
- `gl-adopt-resource-with-helm-v3 {arguments}`: Used only internally in the [cert-manager's](https://cert-manager.io/) Helmfile to
  facilitate the GitLab Managed Apps adoption.
- `gl-adopt-crds-with-helm-v3 {arguments}`: Used only internally in the [cert-manager's](https://cert-manager.io/) Helmfile to
  facilitate the GitLab Managed Apps adoption.
- `gl-helmfile {arguments}`: A thin wrapper that triggers the [Helmfile](https://github.com/roboll/helmfile) command.

#### The main `helmfile.yml` file

This file has a list of paths to other Helmfiles for each app. They're all commented out by default, so you must uncomment
the paths for the apps that you would like to manage.

By default, each `helmfile.yaml` in these sub-paths will have the attribute `installed: true`, which signifies that everytime
the pipeline runs, Helmfile will try to either install or update your apps according to the current state of your
cluster and Helm releases. If you change this attribute to `installed: false`, Helmfile will try to uninstall this app
from your cluster. [Read more](https://github.com/roboll/helmfile) about how Helmfile works.

Furthermore, each app has an `applications/{app}/values.yaml` file. This is the
place where you can define some default values for your app's Helm chart. Some apps will already have defaults
pre-defined by GitLab.

#### Built-in applications

The built-in applications are intended to provide an easy way to get started with various Kubernetes oriented GitLab features.

The [built-in supported applications](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/tree/master/applications) are:

- Apparmor
- Cert-manager
- Cilium
- Elastic Stack
- Falco
- Fluentd
- GitLab Runner
- Ingress
- Prometheus
- Sentry
- Vault

### Migrating from GitLab Managed Apps

If you had GitLab Managed Apps, either One-Click or CI/CD install, read the docs on how to
[migrate from GitLab Managed Apps to project template](migrating_from_gma_to_project_template.md)
