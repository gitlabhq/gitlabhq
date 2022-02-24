---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Manage cluster applications **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25318) in GitLab 12.10 with Helmfile support via Helm v2.
> - Helm v2 support was [dropped](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63577) in GitLab 14.0. Use Helm v3 instead.
> - [Migrated](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/merge_requests/24) to the GitLab agent in GitLab 14.5.

Use a repository to install, manage, and deploy clusters applications through code.

## Cluster Management Project Template

The Cluster Management Project Template provides you a baseline to get
started and flexibility to customize your project to your cluster's needs.
For instance, you can:

- Extend the CI/CD configuration.
- Configure the built-in cluster applications.
- Remove the built-in cluster applications you don't need.
- Add other cluster applications using the same structure as the ones already available.

The template contains the following [components](#configure-the-available-components):

- A pre-configured `.gitlab-ci.yml`file so that you can configure CI/CD pipelines using [the agent for Kubernetes](agent/ci_cd_tunnel.md).
- A pre-configured [Helmfile](https://github.com/roboll/helmfile) so that
you can manage cluster applications with [Helm v3](https://helm.sh/).
- An `applications` directory with a `helmfile.yaml` configured for each
application available in the template.

## Use the agent with the Cluster Management Project Template

To use a new project created from the Cluster Management Project Template
with a cluster connected to GitLab through the [GitLab agent](agent/index.md),
you have two options:

- [Use one single project](#single-project) to configure the agent and manage cluster applications.
- [Use separate projects](#separate-projects) - one to configure the agent and another to manage cluster applications.

### Single project

This setup is particularly useful when you haven't connected your cluster
to GitLab through the agent yet and you want to use the Cluster Management
Project Template to manage cluster applications.

To use one single project to configure the agent and to manage cluster applications:

1. [Create a new project from the Cluster Management Project Template](#create-a-new-project-based-on-the-cluster-management-template).
1. Configure the new project as the [agent's configuration repository](agent/repository.md)
(where the agent is registered and its `config.yaml` is stored).
1. From your project's settings, add a [new environment variable](../../ci/variables/index.md#add-a-cicd-variable-to-a-project) `$KUBE_CONTEXT` and set it to `path/to/agent-configuration-project:your-agent-name`.
1. [Configure the components](#configure-the-available-components) inherited from the template.

### Separate projects

This setup is particularly useful **when you already have a cluster** connected
to GitLab through the agent and want to use the Cluster Management
Project Template to manage cluster applications.

To use one project to configure the agent ("project A") and another project to
manage cluster applications ("project B"), follow the steps below.

We assume that you already have a cluster connected through the agent and
[configured through the agent's configuration repository](agent/repository.md)
("project A").

1. [Create a new project from the Cluster Management Project Template](#create-a-new-project-based-on-the-cluster-management-template).
This new project is "project B".
1. In your "project A", [grant the agent access to the new project (B)](agent/ci_cd_tunnel.md#authorize-the-agent).
1. From the "project's B" settings, add a [new environment variable](../../ci/variables/index.md#add-a-cicd-variable-to-a-project) `$KUBE_CONTEXT` and set it to `path/to/agent-configuration-project:your-agent-name`.
1. In "project B", [configure the components](#configure-the-available-components) inherited from the template.

## Create a new project based on the Cluster Management Template

To get started, create a new project based on the Cluster Management
project template to use as a cluster management project.

You can either create the new project from the template or import the
project from the URL. Importing the project is useful if you are using
a GitLab self-managed instance that may not have the latest version of
the template.

To [create the new project](../project/working_with_projects.md#create-a-project):

- From the template: select the **GitLab Cluster Management** project template.
- Importing from the URL: use `https://gitlab.com/gitlab-org/project-templates/cluster-management.git`.

## Configure the available components

Use the available components to configure your cluster applications:

- [The `.gitlab-ci.yml` file](#the-gitlab-ciyml-file).
- [The main `helmfile.yml` file](#the-main-helmfileyml-file).
- [The directory with built-in applications](#built-in-applications).

### The `.gitlab-ci.yml` file

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

### The main `helmfile.yml` file

This file has a list of paths to other Helmfiles for each app. They're all commented out by default, so you must uncomment
the paths for the apps that you would like to use in your cluster.

By default, each `helmfile.yaml` in these sub-paths has the attribute `installed: true`. This means that every time
the pipeline runs, Helmfile tries to either install or update your apps according to the current state of your
cluster and Helm releases. If you change this attribute to `installed: false`, Helmfile tries try to uninstall this app
from your cluster. [Read more](https://github.com/roboll/helmfile) about how Helmfile works.

### Built-in applications

The [built-in supported applications](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/tree/master/applications) are:

- [Apparmor](../infrastructure/clusters/manage/management_project_applications/apparmor.md)
- [Cert-manager](../infrastructure/clusters/manage/management_project_applications/certmanager.md)
- [Cilium](../infrastructure/clusters/manage/management_project_applications/cilium.md)
- [Elastic Stack](../infrastructure/clusters/manage/management_project_applications/elasticstack.md)
- [Falco](../infrastructure/clusters/manage/management_project_applications/falco.md)
- [Fluentd](../infrastructure/clusters/manage/management_project_applications/fluentd.md)
- [GitLab Runner](../infrastructure/clusters/manage/management_project_applications/runner.md)
- [Ingress](../infrastructure/clusters/manage/management_project_applications/ingress.md)
- [Prometheus](../infrastructure/clusters/manage/management_project_applications/prometheus.md)
- [Sentry](../infrastructure/clusters/manage/management_project_applications/sentry.md)
- [Vault](../infrastructure/clusters/manage/management_project_applications/vault.md)

#### Customize your applications

Each app has an `applications/{app}/values.yaml` file (`applications/{app}/values.yaml.gotmpl` in case of GitLab Runner). This is the
place where you can define default values for your app's Helm chart. Some apps already have defaults
pre-defined by GitLab.
