---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Infrastructure as Code with OpenTofu and GitLab
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

To manage your infrastructure with GitLab, you can use the integration with OpenTofu to define resources that you can version, reuse, and share:

- Manage low-level components like compute, storage, and networking resources.
- Manage high-level components like DNS entries and SaaS features.
- Use GitLab as an OpenTofu state storage.
- Store and use OpenTofu modules to simplify common and complex infrastructure patterns.
- Incorporate GitOps deployments and Infrastructure-as-Code (IaC) workflows.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> Watch [a video overview](https://www.youtube.com/watch?v=iGXjUrkkzDI) of the features GitLab provides with the integration with OpenTofu.

The following examples primarily use OpenTofu, but they can work with Terraform as well.

## Terraform and OpenTofu support

GitLab integrates with both Terraform and OpenTofu.
Most features are fully compatible, including:

- [GitLab-managed Terraform/OpenTofu state](terraform_state.md)
- [Terraform/OpenTofu integration in merge requests](mr_integration.md)
- [Terraform/OpenTofu Module Registry](../../packages/terraform_module_registry/_index.md)

For simplicity, the GitLab documentation refers primarily to OpenTofu.
However, differences between the Terraform and OpenTofu integration
are documented.

## Quickstart an OpenTofu project in pipelines

OpenTofu can integrate with all Terraform-specific GitLab features with the
GitLab OpenTofu CI/CD component.

You can add a *validate*, *plan*, and *apply* workflow to your pipeline by including the component:

```yaml
include:
  - component: gitlab.com/components/opentofu/validate-plan-apply@<VERSION>
    inputs:
      version: <VERSION>
      opentofu_version: <OPENTOFU_VERSION>
      root_dir: terraform/
      state_name: production

stages: [validate, build, deploy]
```

For more information about templates, inputs, and how to use the OpenTofu CI/CD component, see the [OpenTofu CI/CD component README](https://gitlab.com/components/opentofu).

## Quickstart a Terraform project in pipelines

WARNING:
The Terraform CI/CD templates are deprecated and will be removed in GitLab 18.0.
See [the deprecation announcement](../../../update/deprecations.md#deprecate-terraform-cicd-templates) for more information.

The integration with GitLab and Terraform happens through GitLab CI/CD.
Use an `include` attribute to add the Terraform template to your project and
customize from there.

To get started, choose the template that best suits your needs:

- [Latest template](#latest-terraform-template-deprecated)
- [Stable template and advanced template](#stable-and-advanced-terraform-templates-deprecated)

All templates:

- Use the [GitLab-managed Terraform state](terraform_state.md) as the Terraform state storage backend.
- Trigger four pipeline stages: `test`, `validate`, `build`, and `deploy`.
- Run Terraform commands: `test`, `validate`, `plan`, and `plan-json`. It also runs the `apply` only on the default branch.
- Check for security problems using [IaC Scanning](../../application_security/iac_scanning/_index.md).

### Latest Terraform template (deprecated)

The [latest template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform.latest.gitlab-ci.yml)
is compatible with the most recent GitLab version. It provides the most recent
GitLab features, but can potentially include breaking changes.

You can safely use the latest Terraform template:

- If you use GitLab.com.
- If you use a self-managed instance updated with every new GitLab release.

### Stable and advanced Terraform templates (deprecated)

If you use earlier versions of GitLab, you might face incompatibility errors
between the GitLab version and the template version. In this case, you can opt
to use one of these templates:

- [The stable template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform.gitlab-ci.yml) with a skeleton that you can built on top of.
- [The advanced template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform/Base.gitlab-ci.yml) to fully customize your setup.

NOTE:
In each GitLab major release (for example, 15.0), the latest templates replace the older ones. This process can introduce breaking changes. You can [use an older version of the template](troubleshooting.md#use-an-older-version-of-the-template) if you need to.

### Use a Terraform template (deprecated)

To use a Terraform template:

1. On the left sidebar, select **Search or go to** and find your project you want to integrate with Terraform.
1. Select **Code > Repository**.
1. Edit your `.gitlab-ci.yml` file, use the `include` attribute to fetch the Terraform template:

   ```yaml
   include:
    # To fetch the latest template, use:
     - template: Terraform.latest.gitlab-ci.yml
    # To fetch the advanced latest template, use:
     - template: Terraform/Base.latest.gitlab-ci.yml
    # To fetch the stable template, use:
     - template: Terraform.gitlab-ci.yml
    # To fetch the advanced stable template, use:
     - template: Terraform/Base.gitlab-ci.yml
   ```

1. Add the variables as described below:

   ```yaml
   variables:
     TF_STATE_NAME: default
     # If your terraform files are in a subdirectory, set TF_ROOT accordingly. For example:
     # TF_ROOT: terraform/production
   ```

1. Optional. Override in your `.gitlab-ci.yml` file the attributes present
   in the template you fetched to customize your configuration.

### Build and host your own Terraform CI/CD templates

Although GitLab no longer distributes the Terraform CI/CD templates
and `terraform-images` (the underlying job images, including `terraform`),
you can still use Terraform in GitLab pipelines.

To learn how to build and host your own templates and images, see the [Terraform Images](https://gitlab.com/gitlab-org/terraform-images)
project.

### Terraform template recipes

For GitLab-curated template recipes, see [Terraform template recipes](terraform_template_recipes.md).

## Related topics

- Use GitLab as a [Terraform/OpenTofu Module Registry](../../packages/terraform_module_registry/_index.md).
- To store state files in local storage or in a remote store, use the [GitLab-managed Terraform/OpenTofu state](terraform_state.md).
- To collaborate on Terraform code changes and IaC workflows, use the
  [Terraform integration in merge requests](mr_integration.md).
- To manage GitLab resources like users, groups, and projects, use the
  [GitLab Terraform provider](https://gitlab.com/gitlab-org/terraform-provider-gitlab).
  The GitLab Terraform provider documentation is available on [the Terraform docs site](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs).
- [Create a new cluster on Amazon Elastic Kubernetes Service (EKS)](../clusters/connect/new_eks_cluster.md).
- [Create a new cluster on Google Kubernetes Engine (GKE)](../clusters/connect/new_gke_cluster.md).
- [Troubleshoot](troubleshooting.md) issues with GitLab and Terraform.
- View [the images that contain the `gitlab-terraform` shell script](https://gitlab.com/gitlab-org/terraform-images).
