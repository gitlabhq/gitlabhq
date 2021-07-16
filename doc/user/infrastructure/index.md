---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Infrastructure as code with Terraform and GitLab **(FREE)**

## Motivation

The Terraform integration features in GitLab enable your GitOps / Infrastructure-as-Code (IaC)
workflows to tie into GitLab authentication and authorization. These features focus on
lowering the barrier to entry for teams to adopt Terraform, collaborate effectively in
GitLab, and support Terraform best practices.

## Quick Start

Use the following `.gitlab-ci.yml` to set up a basic Terraform project integration
for GitLab versions 14.0 and later:

```yaml
include:
  - template: Terraform.gitlab-ci.yml

variables:
  # If not using GitLab's HTTP backend, remove this line and specify TF_HTTP_* variables
  TF_STATE_NAME: default
  TF_CACHE_KEY: default
  # If your terraform files are in a subdirectory, set TF_ROOT accordingly
  # TF_ROOT: terraform/production
```

This template includes some opinionated decisions, which you can override:

- Including the latest [GitLab Terraform Image](https://gitlab.com/gitlab-org/terraform-images).
- Using the [GitLab managed Terraform State](#gitlab-managed-terraform-state) as
  the Terraform state storage backend.
- Creating [four pipeline stages](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform.gitlab-ci.yml):
  `init`, `validate`, `build`, and `deploy`. These stages
  [run the Terraform commands](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform/Base.gitlab-ci.yml)
  `init`, `validate`, `plan`, `plan-json`, and `apply`. The `apply` command only runs on the default branch.

This video from January 2021 walks you through all the GitLab Terraform integration features:

<div class="video-fallback">
  See the video: <a href="https://www.youtube.com/watch?v=iGXjUrkkzDI">Terraform with GitLab</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube.com/embed/iGXjUrkkzDI" frameborder="0" allowfullscreen="true"> </iframe>
</figure>

## GitLab Managed Terraform state

[Terraform remote backends](https://www.terraform.io/docs/language/settings/backends/index.html)
enable you to store the state file in a remote, shared store. GitLab uses the
[Terraform HTTP backend](https://www.terraform.io/docs/language/settings/backends/http.html)
to securely store the state files in local storage (the default) or
[the remote store of your choice](../../administration/terraform_state.md).

The GitLab managed Terraform state backend can store your Terraform state easily and
securely. It spares you from setting up additional remote resources like
Amazon S3 or Google Cloud Storage. Its features include:

- Supporting encryption of the state file both in transit and at rest.
- Locking and unlocking state.
- Remote Terraform plan and apply execution.

Read more on setting up and [using GitLab Managed Terraform states](terraform_state.md)

WARNING:
Like any other job artifact, Terraform plan data is [viewable by anyone with Guest access](../permissions.md) to the repository.
Neither Terraform nor GitLab encrypts the plan file by default. If your Terraform plan
includes sensitive data such as passwords, access tokens, or certificates, GitLab strongly
recommends encrypting plan output or modifying the project visibility settings.

## Terraform module registry

GitLab can be used as a [Terraform module registry](../packages/terraform_module_registry/index.md)
to create and publish Terraform modules to a private registry specific to your
top-level namespace.

## Terraform integration in Merge Requests

Collaborating around Infrastructure as Code (IaC) changes requires both code changes
and expected infrastructure changes to be checked and approved. GitLab provides a
solution to help collaboration around Terraform code changes and their expected
effects using the Merge Request pages. This way users don't have to build custom
tools or rely on 3rd party solutions to streamline their IaC workflows.

Read more on setting up and [using the merge request integrations](mr_integration.md).

## The GitLab Terraform provider

WARNING:
The GitLab Terraform provider is released separately from GitLab.
We are working on migrating the GitLab Terraform provider for GitLab.com.

You can use the [GitLab Terraform provider](https://github.com/gitlabhq/terraform-provider-gitlab)
to manage various aspects of GitLab using Terraform. The provider is an open source project,
owned by GitLab, where everyone can contribute.

The [documentation of the provider](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs)
is available as part of the official Terraform provider documentations.

## Create a new cluster through IaC

Learn how to [create a new cluster on Google Kubernetes Engine (GKE)](clusters/connect/new_gke_cluster.md).

## Troubleshooting

### `gitlab_group_share_group` resources not detected when subgroup state is refreshed

The GitLab Terraform provider can fail to detect existing `gitlab_group_share_group` resources
due to the issue ["User with permissions cannot retrieve `share_with_groups` from the API"](https://gitlab.com/gitlab-org/gitlab/-/issues/328428).
This results in an error when running `terraform apply` because Terraform attempts to recreate an
existing resource. 

For example, consider the following group/subgroup configuration:

```plaintext
parent-group
├── subgroup-A
└── subgroup-B
```

Where:

- User `user-1` creates `parent-group`, `subgroup-A`, and `subgroup-B`.
- `subgroup-A` is shared with `subgroup-B`.
- User `terraform-user` is member of `parent-group` with inherited `owner` access to both subgroups.

When the Terraform state is refreshed, the API query `GET /groups/:subgroup-A_id` issued by the provider does not return the
details of `subgroup-B` in the `shared_with_groups` array. This leads to the error.

To workaround this issue, make sure to apply one of the following conditions:

1. The `terraform-user` creates all subgroup resources.
1. Grant Maintainer or Owner role to the `terraform-user` user on `subgroup-B`.
1. The `terraform-user` inherited access to `subgroup-B` and `subgroup-B` contains at least one project.
