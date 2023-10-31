---
status: proposed
creation-date: "2023-10-26"
authors: [ "@sgoldstein" ]
coach: "@jessieay"
approvers: []
owning-stage: "~devops::verify"
participating-stages: ["~devops::verify", "~devops::package", "~devops::govern"]
---

<!-- Blueprints often contain forward-looking statements -->
<!-- vale gitlab.FutureTense = NO -->

# GCP Integration

## Summary

GitLab and Google Cloud Platform (GCP) provide complementary tooling which we are integrating via our [partnership](https://about.gitlab.com/blog/2023/08/29/gitlab-google-partnership-s3c/).

As phase 1 of this integration, we plan to:

1. Authentication/Authorization Integration. Onboarding, account-linking and permission management between GitLab and GCP Identities.
1. Continuous Integration. Provision Runners into linked GCP projects.
1. Artifact Management. Package Registry integration with Google Artifact Registry.

This design doc intends to capture the architecture for this initial integration phase. It should answer the following:

1. How users, permissions, and service accounts managed between GitLab and GCP identities
1. How to automatically provision GitLab Runners on Google Cloud Compute (GCE) in GCP customer project via Terraform, with or without VPC configured
1. How to automatically push containers from GitLab CI to Google Artifact Registry, view those containers in GitLab, and trace to builds.

NOTE:
GitLab package team has begun work on architecture design in [Google Artifact Registry Integration](../google_artifact_registry_integration/index.md)

## Decisions

- [ADR-001: Do not store GCP credentials in GitLab](decisions/001_no_credentials.md)

## Proposal

### Authentication/Authorization

Rely primarily on [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation) to manage authorization across the platform. This enables a GitLab user to authenticate within GCP via OAuth and have the ability to assume IAM roles in GCP based on their GitLab user attributes.

#### Workload Identity Pool Provider creation in GCP

As a GCP and GitLab customer (GitLab Group Owner), I would like to create a Workload Identity Pool and Provider to allow GitLab users to authenticate with GCP when executing CI workloads that utilize GCP services.

Steps:

 1. Customer navigates to GitLab → Operate → Google Cloud
 1. Customer authenticates with GCP through an OAuth flow, if the customer is not already authenticated.
 1. Creates a GCP Workload Identity Pool and Provider with OpenID Connect configuration in customers GCP Project, by providing the GCP project number at creation time.
     1. There is an [API to go from projectNum->projectID and back](https://cloud.google.com/resource-manager/reference/rest/v3/projects/get).

#### GCP resource policy creation in GitLab for Workload Identity Provider

As a GCP customer, I would like to authorize GitLab’s use of my GCP resources for the purpose of the GitLab - GCP Integration:

Steps:

1. Customer navigates to GitLab → Operate → Google Cloud
1. Customer authenticates with GCP through an OAuth flow, if the customer is not already authenticated.
1. Customer selects previously created Workload Identity Provider and adds applicable resource policies by specifying the:
    1. GCP project number
    1. One or more GitLab OpenID claims and associated values to use for authenticating a workload
    1. One or more GCP resources IAM roles the authenticated workload will be authorized to use
1. Customer is presented with a prompt asking them to confirm that they wish to proceed in creating this GCP resource policy
    1. If a customer confirms, a policy for the Workload Identity Provider is created in the specified GCP project.
1. If additional GCP resource policies are required, the customer can repeat steps 2 and 3.

NOTE:
The user should also be able to edit (claims, values and IAM roles) and delete GCP resources policies.

#### User to User authentication linkage

As an existing GitLab user, I can use OAuth to link my existing GCP account so that I can seamlessly exchange data between the two

This will be used for the following use cases:

 1. In Artifact Registry where the individual user can see artifacts in GCP
 1. Creation of workload identity federation pools
 1. List, pull and push images to Artifact Registry from GitLab

Also applies in the reverse direction. Existing GCP users can OAuth into GitLab and link their accounts.

#### Runner Provisioning

TBA

#### GitLab CI to Google Artifact Registry Authn/Authz

TBA

## Design and implementation details
