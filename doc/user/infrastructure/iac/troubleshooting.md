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
