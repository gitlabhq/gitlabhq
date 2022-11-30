---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Terraform template recipes **(FREE)**

To customize your Terraform integration, you can add the recipes on this page to your pipeline using Terraform templates.

If you'd like to share your own Terraform configuration, consider [contributing a recipe](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/user/infrastructure/iac/tf_template_recipes.md) to this page.

## Enable a `terraform destroy` job

To enable a `terraform destroy` job, add the following snippet to your `.gitlab-ci.yml`:

```yaml
include:
  - template: Terraform.latest.gitlab-ci.yml

destroy:
  extends: .terraform:destroy
```

The `destroy` job is part of the `cleanup` stage. Like the `deploy` job, the `destroy` job is always `manual`
and is not tied to the default branch.

## Run a custom `terraform` command in a job

To define a job that runs a custom `terraform` command, the `gitlab-terraform` wrapper can be used in any job, like this:

```yaml
include:
  - template: Terraform.latest.gitlab-ci.yml

state-list:
  stage: validate # you can use any stage, just make sure to define it
  script: gitlab-terraform state list
```

The `gitlab-terraform` command sets up a `terraform` command and just forward the given arguments.

To run this job in the Terraform state-specific [resource group](../../../ci/resource_groups/index.md), assign the job with `resource_group`:

```yaml
include:
  - template: Terraform.latest.gitlab-ci.yml

state-list:
  stage: validate # you can use any stage, just make sure to define it
  resource_group: ${TF_STATE_NAME}
  script: gitlab-terraform state list
```
