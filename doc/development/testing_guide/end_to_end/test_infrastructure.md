---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: End-to-end Testing Infrastructure for Cloud Integrations
---

This content is about infrastructure we integrate with GitLab QA test scenarios, at the end-to-end level.

## What infrastructure do we have in place?

We currently use GCP and AWS platforms to test a few end-to-end scenarios. These are separated from other
sandbox projects to prevent accidental deletion of resources that run beyond automated test runs. If you do not have
access to these accounts already, you can create an access request. In GCP, we use `group-qa-tests-566cc6`
and in AWS, the cloud account `eng-quality-ops-ci-cd-shared-infra-498dbd5a`.

If you have test scenarios that require these platforms, we encourage you to use the existing infrastructure and
accounts so we can efficiently consolidate and maintain our end-to-end test suite.

## Why do we have this infrastructure?

GitLab has several features that integrate well with known Cloud Providers. To fully test this integration,
we have infrastructure in place that connects GitLab QA with these providers.

We currently use GCP for its Cloud Storage resources to test Object Storage (GCS) and to create Kubernetes clusters. We also use AWS to test Object Storage (S3).

## How do we maintain this infrastructure?

We have an active [Janitor](https://gitlab.com/gitlab-com/gl-infra/gitlab-gcp-janitor) project that ensures resources in GCP are cleaned up if a test fails to remove it. The Janitor jobs run daily on a scheduled pipeline and target exclusively GCP `group-qa-tests-566cc6`.

AWS uses lifecycle management rules to delete objects after 1 day. We have an established [process](https://gitlab.com/gitlab-org/quality/engineering-productivity/team/-/blob/main/runbooks/rotating-credentials.md) that enables anyone with access to these environments to rotate credentials.
