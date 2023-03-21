---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference
---

# Terraform limits **(FREE SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352951) in GitLab 15.7.

You can limit the total storage of [Terraform state files](../../../administration/terraform_state.md).
The limit applies to each individual
state file version, and is checked whenever a new version is created.

To add a storage limit:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > Preferences**.
1. Expand **Terraform limits**.
1. Adjust the size limit.

## Available settings

| Setting                            | Default | Description                                                                                                                                             |
|------------------------------------|---------|---------------------------------------------------------------------------------------------------------------------------------------------------------|
| Terraform state size limit (bytes) | 0       | Terraform state files that exceed this size are not saved, and associated Terraform operations are rejected. Set to 0 to allow files of unlimited size. |
