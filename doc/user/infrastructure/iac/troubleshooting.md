---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Troubleshooting the Terraform integration with GitLab

When you are using the integration with Terraform and GitLab, you might experience issues you need to troubleshoot.

## `gitlab_group_share_group` resources not detected when subgroup state is refreshed

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

### Invalid CI/CD syntax error when using the `latest` base template

On GitLab 14.2 and later, you might get a CI/CD syntax error when using the
`latest` Base Terraform template:

```yaml
include:
  - template: Terraform/Base.latest.gitlab-ci.yml

my-Terraform-job:
  extends: .init
```

The base template's [jobs were renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/67719/)
with better Terraform-specific names. To resolve the syntax error, you can:

- Use the stable `Terraform/Base.gitlab-ci.yml` template, which has not changed.
- Update your pipeline configuration to use the new job names in
  `https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Terraform/Base.latest.gitlab-ci.yml`.
  For example:

  ```yaml
  include:
    - template: Terraform/Base.latest.gitlab-ci.yml

  my-Terraform-job:
    extends: .terraform:init  # The updated name.
  ```

## Troubleshooting Terraform state

### Unable to lock Terraform state files in CI jobs for `terraform apply` using a plan created in a previous job

When passing `-backend-config=` to `terraform init`, Terraform persists these values inside the plan
cache file. This includes the `password` value.

As a result, to create a plan and later use the same plan in another CI job, you might get the error
`Error: Error acquiring the state lock` errors when using `-backend-config=password=$CI_JOB_TOKEN`.
This happens because the value of `$CI_JOB_TOKEN` is only valid for the duration of the current job.

As a workaround, use [http backend configuration variables](https://www.terraform.io/docs/language/settings/backends/http.html#configuration-variables) in your CI job,
which is what happens behind the scenes when following the
[Get started using GitLab CI](terraform_state.md#get-started-using-gitlab-ci) instructions.

### Error: "address": required field is not set

By default, we set `TF_ADDRESS` to `${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${TF_STATE_NAME}`.
If you don't set `TF_STATE_NAME` or `TF_ADDRESS` in your job, the job fails with the error message
`Error: "address": required field is not set`.

To resolve this, ensure that either `TF_ADDRESS` or `TF_STATE_NAME` is accessible in the
job that returned the error:

1. Configure the [CI/CD environment scope](../../../ci/variables/#add-a-cicd-variable-to-a-project) for the job.
1. Set the job's [environment](../../../ci/yaml/#environment), matching the environment scope from the previous step.
