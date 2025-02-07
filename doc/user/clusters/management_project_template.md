---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Manage cluster applications
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

GitLab provides a cluster management project template, which you use
to create a project. The project includes cluster applications that integrate with GitLab
and extend GitLab functionality. You can use the pattern shown in the project to extend
your custom cluster applications.

NOTE:
The project template works on GitLab.com without modifications. If you're on a self-managed instance, you must modify the `.gitlab-ci.yml` file.

## Use one project for the agent and your manifests

If you **have not yet** used the agent to connect your cluster with GitLab:

1. [Create a project from the cluster management project template](#create-a-project-based-on-the-cluster-management-project-template).
1. [Configure the project for the agent](agent/install/_index.md).
1. In your project's settings, create an
   [environment variable](../../ci/variables/_index.md#for-a-project) named `$KUBE_CONTEXT`
   and set the value to `path/to/agent-configuration-project:your-agent-name`.
1. [Configure the files](#configure-the-project) as needed.

## Use separate projects for the agent and your manifests

If you have already configured the agent and connected a cluster with GitLab:

1. [Create a project from the cluster management project template](#create-a-project-based-on-the-cluster-management-project-template).
1. In the project where you configured your agent,
   [grant the agent access to the new project](agent/ci_cd_workflow.md#authorize-the-agent).
1. In the new project, create an
   [environment variable](../../ci/variables/_index.md#for-a-project) named `$KUBE_CONTEXT`
   and set the value to `path/to/agent-configuration-project:your-agent-name`.
1. In the new project, [configure the files](#configure-the-project) as needed.

## Create a project based on the cluster management project template

To create a project from the cluster management project template:

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Create from template**.
1. From the list of templates, next to **GitLab Cluster Management**, select **Use template**.
1. Enter the project details.
1. Select **Create project**.
1. In the new project, [configure the files](#configure-the-project) as needed.

## Configure the project

After you use the cluster management template to create a project, you can configure:

- [The `.gitlab-ci.yml` file](#the-gitlab-ciyml-file).
- [The main `helmfile.yml` file](#the-main-helmfileyml-file).
- [The directory with built-in applications](#built-in-applications).

### The `.gitlab-ci.yml` file

The `.gitlab-ci.yml` file:

- Ensures you are on Helm version 3.
- Deploys the enabled applications from the project.

You can edit and extend the pipeline definitions.

The base image used in the pipeline is built by the
[cluster-applications](https://gitlab.com/gitlab-org/cluster-integration/cluster-applications) project.
This image contains a set of Bash utility scripts to support [Helm v3 releases](https://helm.sh/docs/intro/using_helm/#three-big-concepts).

If you are on a self-managed instance of GitLab, you must modify the `.gitlab-ci.yml` file.
Specifically, the section that starts with the comment `Automatic package upgrades` does not
work on a self-managed instance, because the `include` refers to a GitLab.com project.
If you remove everything below this comment, the pipeline succeeds.

### The main `helmfile.yml` file

The template contains a [Helmfile](https://github.com/helmfile/helmfile) you can use to manage
cluster applications with [Helm v3](https://helm.sh/).

This file has a list of paths to other Helm files for each app. They're all commented out by default, so you must uncomment
the paths for the apps that you would like to use in your cluster.

By default, each `helmfile.yaml` in these sub-paths has the attribute `installed: true`. This means that, depending on the state of your cluster and Helm releases, Helmfile attempts to install or update apps every time the pipeline runs. If you change this attribute to `installed: false`, Helmfile tries to uninstall this app
from your cluster. [Read more](https://helmfile.readthedocs.io/en/latest/) about how Helmfile works.

### Built-in applications

The template contains an `applications` directory with a `helmfile.yaml` configured for each
application in the template.

The [built-in supported applications](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/tree/master/applications) are:

- [Cert-manager](../infrastructure/clusters/manage/management_project_applications/certmanager.md)
- [GitLab Runner](../infrastructure/clusters/manage/management_project_applications/runner.md)
- [Ingress](../infrastructure/clusters/manage/management_project_applications/ingress.md)
- [Vault](../infrastructure/clusters/manage/management_project_applications/vault.md)

Each application has an `applications/{app}/values.yaml` file.
For GitLab Runner, the file is `applications/{app}/values.yaml.gotmpl`.

In this file, you can define default values for your app's Helm chart.
Some apps already have defaults defined.
