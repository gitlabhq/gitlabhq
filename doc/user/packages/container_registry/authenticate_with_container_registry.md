---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Authenticate with the container registry

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

To authenticate with the container registry, you can use a:

- [Personal access token](../../profile/personal_access_tokens.md).
- [Deploy token](../../project/deploy_tokens/index.md).
- [Project access token](../../project/settings/project_access_tokens.md).
- [Group access token](../../group/settings/group_access_tokens.md).

All of these authentication methods require the minimum scope:

- For read (pull) access, to be `read_registry`.
- For write (push) access, to be `write_registry` and `read_registry`.

To authenticate, run the `docker login` command. For example:

```shell
TOKEN=<token>
docker login registry.example.com -u <username> --password-stdin <<<$TOKEN
```

## Use GitLab CI/CD to authenticate

To use CI/CD to authenticate with the container registry, you can use:

- The `CI_REGISTRY_USER` CI/CD variable.

  This variable holds a per-job user with read-write access to the container registry.
  Its password is also automatically created and available in `CI_REGISTRY_PASSWORD`.

  ```shell
  docker login $CI_REGISTRY -u $CI_REGISTRY_USER --password-stdin <<<$CI_REGISTRY_PASSWORD
  ```

- A [CI job token](../../../ci/jobs/ci_job_token.md).

  ```shell
  docker login $CI_REGISTRY -u $CI_REGISTRY_USER --password-stdin <<<$CI_JOB_TOKEN
  ```

- A [deploy token](../../project/deploy_tokens/index.md#gitlab-deploy-token) with the minimum scope of:
  - For read (pull) access, `read_registry`.
  - For write (push) access, `read_registry` and `write_registry`.

  ```shell
  docker login $CI_REGISTRY -u $CI_DEPLOY_USER --password-stdin <<<$CI_DEPLOY_PASSWORD
  ```

- A [personal access token](../../profile/personal_access_tokens.md) with the minimum scope of:
  - For read (pull) access, `read_registry`.
  - For write (push) access, `read_registry` and `write_registry`.

  ```shell
  docker login $CI_REGISTRY -u <username> -p <access_token>
  ```
