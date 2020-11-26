---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Infrastructure as code with Terraform and GitLab

## Motivation

The Terraform integration features within GitLab enable your GitOps / Infrastructure-as-Code (IaC)
workflows to tie into GitLab's authentication and authorization. These features focus on
lowering the barrier to entry for teams to adopt Terraform, collaborate effectively within
GitLab, and support Terraform best practices.

## GitLab Managed Terraform state

[Terraform remote backends](https://www.terraform.io/docs/backends/index.html)
enable you to store the state file in a remote, shared store. GitLab uses the
[Terraform HTTP backend](https://www.terraform.io/docs/backends/types/http.html)
to securely store the state files in local storage (the default) or
[the remote store of your choice](../../administration/terraform_state.md).

The GitLab managed Terraform state backend can store your Terraform state easily and
securely, and spares you from setting up additional remote resources like
Amazon S3 or Google Cloud Storage. Its features include:

- Supporting encryption of the state file both in transit and at rest.
- Locking and unlocking state.
- Remote Terraform plan and apply execution.

Read more on setting up and [using GitLab Managed Terraform states](terraform_state.md)

## Terraform integration in Merge Requests

Collaborating around Infrastructure as Code (IaC) changes requires both code changes and expected infrastructure changes to be checked and approved. GitLab provides a solution to help collaboration around Terraform code changes and their expected effects using the Merge Request pages. This way users don't have to build custom tools or rely on 3rd party solutions to streamline their IaC workflows.

Read more on setting up and [using the merge request integrations](mr_integration.md).

## Quick Start

Use the following `.gitlab-ci.yml` to set up a simple Terraform project integration
for GitLab versions 13.5 and greater:

```yaml
include:
  - template: Terraform.latest.gitlab-ci.yml

variables:
  # If not using GitLab's HTTP backend, remove this line and specify TF_HTTP_* variables
  TF_STATE_NAME: default
  TF_CACHE_KEY: default
```

This template uses `.latest.`, instead of stable, and may include breaking changes.
This template also includes some opinionated decisions, which you can override:

- Including the latest [GitLab Terraform Image](https://gitlab.com/gitlab-org/terraform-images).
- Using the [GitLab managed Terraform State](#gitlab-managed-terraform-state) as
  the Terraform state storage backend.
- Creating [four pipeline stages](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform.latest.gitlab-ci.yml):
  `init`, `validate`, `build`, and `deploy`. These stages
  [run the Terraform commands](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform/Base.latest.gitlab-ci.yml)
  `init`, `validate`, `plan`, `plan-json`, and `apply`. The `apply` command only runs on `master`.
