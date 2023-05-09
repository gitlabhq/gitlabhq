---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Authenticate with the Container Registry **(FREE)**

<!--- start_remove The following content will be removed on remove_date: '2023-11-22' -->
WARNING:
In GitLab 16.0 and later, [external authorization](../../admin_area/settings/external_authorization.md) prevents personal access tokens and deploy tokens from accessing container and package registries and affects all users who use these tokens to access the registries. You can disable external authorization if you want to use personal access tokens and deploy tokens with the container or package registries.
<!--- end_remove -->

To authenticate with the Container Registry, you can use a:

- [Personal access token](../../profile/personal_access_tokens.md).
- [Deploy token](../../project/deploy_tokens/index.md).
- [Project access token](../../project/settings/project_access_tokens.md).
- [Group access token](../../group/settings/group_access_tokens.md).

All of these authentication methods require the minimum scope:

- For read (pull) access, to be `read_registry`.
- For write (push) access, to be`write_registry` and `read_registry`.

To authenticate, run the `docker login` command. For example:

   ```shell
   docker login registry.example.com -u <username> -p <token>
   ```

## Use GitLab CI/CD to authenticate

To use CI/CD to authenticate with the Container Registry, you can use:

- The `CI_REGISTRY_USER` CI/CD variable.

  This variable has read-write access to the Container Registry and is valid for
  one job only. Its password is also automatically created and assigned to `CI_REGISTRY_PASSWORD`.

  ```shell
  docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  ```

- A [CI job token](../../../ci/jobs/ci_job_token.md).

  ```shell
  docker login -u $CI_REGISTRY_USER -p $CI_JOB_TOKEN $CI_REGISTRY
  ```

- A [deploy token](../../project/deploy_tokens/index.md#gitlab-deploy-token) with the minimum scope of:
  - For read (pull) access, `read_registry`.
  - For write (push) access, `write_registry`.

  ```shell
  docker login -u $CI_DEPLOY_USER -p $CI_DEPLOY_PASSWORD $CI_REGISTRY
  ```

- A [personal access token](../../profile/personal_access_tokens.md) with the minimum scope of:
  - For read (pull) access, `read_registry`.
  - For write (push) access, `write_registry`.

  ```shell
  docker login -u <username> -p <access_token> $CI_REGISTRY
  ```
