---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Infrastructure as Code with OpenTofu and GitLab
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

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

## Build and host your own Terraform CI/CD templates

Although GitLab no longer distributes the Terraform CI/CD templates
and `terraform-images` (the underlying job images, including `terraform`),
you can still use Terraform in GitLab pipelines.

To learn how to build and host your own templates and images, see the [Terraform Images](https://gitlab.com/gitlab-org/terraform-images)
project.

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
