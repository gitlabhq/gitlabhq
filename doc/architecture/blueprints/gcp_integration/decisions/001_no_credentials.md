---
description: 'GCP Integration ADR 001: Do not store GCP credentials in GitLab'
---

# GCP Integration ADR 001: Do not store GCP credentials in GitLab

## Context

Users need to be able to perform certain actions within GCP based on their
GitLab project membership and permissions. For example, users of the
integration need a mechanism to push packages to the Google Artifact Registry
and to provision Runners within their GCP projects.

## Decision

Rely primarily on [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
to manage authorization across the platform. This enables a GitLab user or a
group / project owner to authenticate within GCP via OAuth and have the ability
to assume / configure IAM roles in GCP based on their GitLab user attributes.
