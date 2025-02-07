---
stage: none
group: unassigned
info: This is a GitLab Incubation Engineering program. No technical writer assigned to this group.
ignore_in_report: true
title: Cloud Seed
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/371332) in GitLab 15.4 [with a flag](../administration/feature_flags.md) named `google_cloud`. Disabled by default.
> - [Enabled on GitLab Self-Managed and GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/100545) in GitLab 15.5.

Cloud Seed is an open-source program led
by [GitLab Incubation Engineering](https://handbook.gitlab.com/handbook/engineering/development/incubation/) in collaboration with
[Google Cloud](https://cloud.google.com/).

Cloud Seed combines Heroku-like ease-of-use with hyper-cloud flexibility. We do this by using OAuth 2 to provision
services on a hyper-cloud based on a foundation of Terraform and infrastructure-as-code to enable day 2 operations.

## Purpose

We believe that it should be **trivial** to deploy web applications (and other workloads) from GitLab to major cloud
providers.

To support this effort, Cloud Seed makes it straightforward and intuitive to consume appropriate Google Cloud services
in GitLab.

## Why Google Cloud

*or Why not AWS or Azure?*

Cloud Seed is an open-source program that can be extended by anyone, and we'd love to work with every major cloud
provider. We chose to work with Google Cloud because their team is accessible, supportive, and collaborative in
this effort.

As an open-source project, [everyone can contribute](#contribute-to-cloud-seed) and shape our direction.

## Deploy to Google Cloud Run

After you have your web application in a GitLab project, follow these steps
to deploy your application from GitLab to Google Cloud with Cloud Seed:

1. [Set up deployment credentials](#set-up-deployment-credentials)
1. (Optional) [Configure your preferred GCP region](#configure-your-preferred-gcp-region)
1. [Configure the Cloud Run deployment pipeline](#configure-the-cloud-run-deployment-pipeline)

### Set up deployment credentials

Cloud Seed provides an interface to create Google Cloud Platform (GCP) service accounts from your GitLab project. The associated GCP project
must be selected during the service account creation workflow. This process generates a service account, keys, and deployment permissions.

To create a service account:

1. Go to the `Project :: Infrastructure :: Google Cloud` page.
1. Select **Create Service Account**.
1. Follow the Google OAuth 2 workflow and authorize GitLab.
1. Select your GCP project.
1. Associate a Git reference (such as a branch or tag) for the selected GCP project.
1. Submit the form to create the service account.

The generated service account, service account key, and associated GCP project ID are stored in GitLab as project CI
variables. You can review and manage these in the `Project :: Settings :: CI` page.

The generated service account has the following roles:

- `roles/iam.serviceAccountUser`
- `roles/artifactregistry.admin`
- `roles/cloudbuild.builds.builder`
- `roles/run.admin`
- `roles/storage.admin`
- `roles/cloudsql.client`
- `roles/browser`

You can enhance security by storing CI variables in secret managers. For more information, see [secret management with GitLab](../ci/secrets/_index.md).

### Configure your preferred GCP region

When you configure GCP regions for your deployments, the list of regions offered is a subset of
all GCP regions available.

To configure a region:

1. Go to the `Project :: Infrastructure :: Google Cloud` page.
1. Select **Configure GCP Region**.
1. Select your preferred GCP region.
1. Associate a Git reference (such as a branch or tag) for the selected GCP region.
1. Submit the form to configure the GCP region.

The configured GCP region is stored in GitLab as a project CI variable. You can review and manage these in
the `Project :: Settings :: CI` page.

### Configure the Cloud Run deployment pipeline

You can configure the Google Cloud Run deployment job in your pipeline. A typical use case for such
a pipeline is continuous deployment of your web application.

The project pipeline itself could have a broader purpose spanning across several stages, such as build, test, and secure.
Therefore, the Cloud Run deployment offering comes packaged as one job that fits into a much larger pipeline.

To configure the Cloud Run deployment pipeline:

1. Go to the `Project :: Infrastructure :: Google Cloud` page.
1. Go to the `Deployments` tab.
1. For `Cloud Run`, select **Configure via Merge Request**.
1. Review the changes and submit to create a merge request.

This creates a new branch with the Cloud Run deployment pipeline (or injected into an existing pipeline)
and creates an associated merge request where the changes and deployment pipeline execution can be reviewed and merged
into the main branch.

## Provision Cloud SQL Databases

Relational database instances can be provisioned from the `Project :: Infrastructure :: Google Cloud` page. Cloud SQL is
the underlying Google Cloud service that is used to provision the database instances.

The following databases and versions are supported:

- PostgreSQL: 14, 13, 12, 11, 10, and 9.6
- MySQL: 8.0, 5.7 and 5.6
- SQL Server
  - 2019: Standard, Enterprise, Express, and Web
  - 2017: Standard, Enterprise, Express, and Web

Google Cloud pricing applies. Refer to the [Cloud SQL pricing page](https://cloud.google.com/sql/pricing).

1. [Create a database instance](#create-a-database-instance)
1. [Database setup through a background worker](#database-setup-through-a-background-worker)
1. [Connect to the database](#connect-to-the-database)
1. [Managing the database instance](#managing-the-database-instance)

### Create a database instance

From the `Project :: Infrastructure :: Google Cloud` page, select the **Database** tab. Here you find three
buttons to create Postgres, MySQL, and SQL Server database instances.

The database instance creation form has fields for GCP project, Git ref (branch or tag), database version and
machine type. Upon submission, the database instance is created and the database setup is queued as a background job.

### Database setup through a background worker

Successful creation of the database instance triggers a background worker to perform the following tasks:

- Create a database user
- Create a database schema
- Store the database details in the project's CI/CD variables

### Connect to the database

After the database instance setup is complete, the database connection details are available as project variables. These
can be managed through the `Project :: Settings :: CI` page and are made available to pipeline executing in the
appropriate environment.

### Managing the database instance

The list of instances in the `Project :: Infrastructure :: Google Cloud :: Databases` links back to the Google Cloud
Console. Select an instance to view the details and manage the instance.

## Contribute to Cloud Seed

There are several ways you can contribute to Cloud Seed:

- Use Cloud Seed and [share feedback](https://gitlab.com/gitlab-org/incubation-engineering/five-minute-production/feedback/-/issues/new?template=general_feedback).
- If you are familiar with Ruby on Rails or Vue.js,
  consider [contributing to GitLab](../development/contributing/_index.md) as a developer.
  - Much of Cloud Seed is an internal module in the GitLab codebase.
- If you are familiar with GitLab pipelines, consider contributing to
  the [Cloud Seed Library](https://gitlab.com/gitlab-org/incubation-engineering/five-minute-production/library) project.
