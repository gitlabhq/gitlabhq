# GitLab CI Documentation

## CI User documentation

- [Getting started with GitLab CI](quick_start/README.md)
- [CI examples for various languages](examples/README.md)
- [Learn how to enable or disable GitLab CI](enable_or_disable_ci.md)
- [Pipelines and jobs](pipelines.md)
- [Environments and deployments](environments.md)
- [Learn how `.gitlab-ci.yml` works](yaml/README.md)
- [Configure a Runner, the application that runs your jobs](runners/README.md)
- [Use Docker images with GitLab Runner](docker/using_docker_images.md)
- [Use CI to build Docker images](docker/using_docker_build.md)
- [CI Variables](variables/README.md) - Learn how to use variables defined in
  your `.gitlab-ci.yml` or secured ones defined in your project's settings
- [Use SSH keys in your build environment](ssh_keys/README.md)
- [Trigger jobs through the API](triggers/README.md)
- [Job artifacts](../user/project/pipelines/job_artifacts.md)
- [User permissions](../user/permissions.md#gitlab-ci)
- [Jobs permissions](../user/permissions.md#jobs-permissions)
- [API](../api/ci/README.md)
- [CI services (linked docker containers)](services/README.md)
- [CI/CD pipelines settings](../user/project/pipelines/settings.md)
- [Review Apps](review_apps/index.md)
- [Git submodules](git_submodules.md) Using Git submodules in your CI jobs
- [Auto deploy](autodeploy/index.md)

## Breaking changes

- [New CI job permissions model](../user/project/new_ci_build_permissions_model.md)
  Read about what changed in GitLab 8.12 and how that affects your jobs.
  There's a new way to access your Git submodules and LFS objects in jobs.
