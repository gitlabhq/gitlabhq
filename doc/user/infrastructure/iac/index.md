---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Infrastructure as Code with Terraform and GitLab **(FREE)**

With Terraform in GitLab, you can use GitLab authentication and authorization with
your GitOps and Infrastructure-as-Code (IaC) workflows.
Use these features if you want to collaborate on Terraform code within GitLab or would like to use GitLab as a Terraform state storage that incorporates best practices out of the box.

## Integrate your project with Terraform

> SAST test was [introduced](https://gitlab.com/groups/gitlab-org/-/epics/6655) in GitLab 14.6.

In GitLab 14.0 and later, to integrate your project with Terraform, add the following
to your `.gitlab-ci.yml` file:

```yaml
include:
  - template: Terraform.latest.gitlab-ci.yml

variables:
  # If you do not use the GitLab HTTP backend, remove this line and specify TF_HTTP_* variables
  TF_STATE_NAME: default
  TF_CACHE_KEY: default
  # If your terraform files are in a subdirectory, set TF_ROOT accordingly
  # TF_ROOT: terraform/production
```

The `Terraform.latest.gitlab-ci.yml` template:

- Uses the latest [GitLab Terraform image](https://gitlab.com/gitlab-org/terraform-images).
- Uses the [GitLab-managed Terraform state](#gitlab-managed-terraform-state) as
  the Terraform state storage backend.
- Creates [four pipeline stages](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform.latest.gitlab-ci.yml):
  `test`, `validate`, `build`, and `deploy`. These stages
  [run the Terraform commands](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform/Base.latest.gitlab-ci.yml)
  `test`, `validate`, `plan`, `plan-json`, and `apply`. The `apply` command only runs on the default branch.
- Runs the [Terraform SAST scanner](../../application_security/iac_scanning/index.md#configure-iac-scanning-manually),
  that you can disable by creating a `SAST_DISABLED` environment variable and setting it to `1`.

You can override the values in the default template by updating your `.gitlab-ci.yml` file.

The latest template might contain breaking changes between major GitLab releases.
For a more stable template, we recommend:

- [A ready-to-use version](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform.gitlab-ci.yml)
- [A base template for customized setups](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform/Base.gitlab-ci.yml)

This video from January 2021 walks you through all the GitLab Terraform integration features:

<div class="video-fallback">
  See the video: <a href="https://www.youtube.com/watch?v=iGXjUrkkzDI">Terraform with GitLab</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube.com/embed/iGXjUrkkzDI" frameborder="0" allowfullscreen="true"> </iframe>
</figure>

## GitLab-managed Terraform state

[Terraform remote backends](https://www.terraform.io/docs/language/settings/backends/index.html)
enable you to store the state file in a remote, shared store. GitLab uses the
[Terraform HTTP backend](https://www.terraform.io/docs/language/settings/backends/http.html)
to securely store the state files in local storage (the default) or
[the remote store of your choice](../../../administration/terraform_state.md).

The GitLab-managed Terraform state backend can store your Terraform state easily and
securely. It spares you from setting up additional remote resources like
Amazon S3 or Google Cloud Storage. Its features include:

- Supporting encryption of the state file both in transit and at rest.
- Locking and unlocking state.
- Remote Terraform plan and apply execution.

Read more about setting up and [using GitLab-managed Terraform states](terraform_state.md).

## Terraform module registry

GitLab can be used as a [Terraform module registry](../../packages/terraform_module_registry/index.md)
to create and publish Terraform modules to a private registry specific to your
top-level namespace.

## Terraform integration in merge requests

Collaborating around Infrastructure as Code (IaC) changes requires both code changes
and expected infrastructure changes to be checked and approved. GitLab provides a
solution to help collaboration around Terraform code changes and their expected
effects using the merge request pages. This way users don't have to build custom
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
is available as part of the official Terraform provider documentation.

## Create a new cluster through IaC

- Learn how to [create a new cluster on Amazon Elastic Kubernetes Service (EKS)](../clusters/connect/new_eks_cluster.md).
- Learn how to [create a new cluster on Google Kubernetes Engine (GKE)](../clusters/connect/new_gke_cluster.md) (DEPRECATED).

NOTE:
The linked GKE tutorial connects the cluster to GitLab through cluster certificates,
and this method was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)
in GitLab 14.5. You can still create a cluster through IaC and then connect it to GitLab
through the [agent](../../clusters/agent/index.md), the default and fully supported
method to connect clusters to GitLab.

## Troubleshooting

See the [troubleshooting](troubleshooting.md) documentation.
