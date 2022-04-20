---
stage: Release
group: Incubation
info: Cloud Seed (formerly 5mp) is a GitLab Incubation Engineering program. No technical writer assigned to this group.
---

# Cloud Seed

Cloud Seed is an open-source program led
by [GitLab Incubation Engineering](https://about.gitlab.com/handbook/engineering/incubation/) in collaboration with
[Google Cloud](https://cloud.google.com/).

Cloud Seed is in `private-testing` mode and is available to a select group of users. If you are interested in joining
this group, please fill in
the [Cloud Seed Trusted Testers invitation form](https://docs.google.com/forms/d/e/1FAIpQLSeJPtFE8Vpqs_YTAKkFK42p5mO9zIYA2jr_PiP2h32cs8R39Q/viewform)
and we will reach out to you.

## Purpose

We believe that it should be **trivial** to deploy web applications (and other workloads) from GitLab to major cloud
providers.

To support this effort, Cloud Seed makes it simple and intuitive to consume appropriate Google Cloud services
within GitLab.

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
- `roles/cloudsql.admin`
- `roles/browser`

You can enhance security by storing CI variables in secret managers. Learn more about [secret management with GitLab](../ci/secrets/index.md).

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

## Contribute to Cloud Seed

There are several ways you can contribute to Cloud Seed:

- [Become a Cloud Seed user](https://docs.google.com/forms/d/e/1FAIpQLSeJPtFE8Vpqs_YTAKkFK42p5mO9zIYA2jr_PiP2h32cs8R39Q/viewform)
  in GitLab
  and [share feedback](https://gitlab.com/gitlab-org/incubation-engineering/five-minute-production/feedback/-/issues/new?template=general_feedback).
- If you are familiar with Ruby on Rails or Vue.js,
  consider [contributing to GitLab](../development/contributing/index.md) as a developer.
  - Much of Cloud Seed is an internal module within the GitLab code base.
- If you are familiar with GitLab pipelines, consider contributing to
  the [Cloud Seed Library](https://gitlab.com/gitlab-org/incubation-engineering/five-minute-production/library) project.
