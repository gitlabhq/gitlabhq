---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Deploying Python repositories
---

## Python Libraries and Utilities

We deploy libraries and utilities to pypi with the [`gitlab` user](https://pypi.org/user/gitlab/) using `poetry`. Configure the deployment in the `pyproject.toml` file:

```toml
[tool.poetry]
name = "gitlab-<your package name>"
version = "0.1.0"
description = "<Description of your library/utility>"
authors = ["gitlab"]
readme = "README.md"
packages = [{ include = "<your module>" }]
homepage = ""https://gitlab.com/gitlab/<path/to/repository>"
repository = "https://gitlab.com/gitlab/<path/to/repository>"
```

Refer to [poetry's documentation](https://python-poetry.org/docs/pyproject/) for additional configuration options.

To configure deployment of the PyPI package:

1. [Authenticate to PyPI](https://pypi.org/account/login/) using the "PyPI GitLab" credentials found in 1Password (PyPI does not support organizations as of now).
1. Create a token under `Account Settings > Add API Tokens`.
1. For the initial publish, select `Entire account (all projects)` scope. If the project already exists, scope the token to the specific project.
1. Configure credentials:

   Locally:

   ```shell
   poetry config pypi-token.pypi <your-api-token>
   ```

   To configure deployment with CI, set the `POETRY_PYPI_TOKEN_PYPI` to the token created. Alternatively, define a [trusted publisher](https://docs.pypi.org/trusted-publishers/) for the project, in which case no token is needed.

1. Use [Poetry to publish](https://python-poetry.org/docs/cli/#publish) your package:

   ```shell
   poetry publish
   ```

## Python Services

### Runway deployment for .com

Services for GitLab.com, GitLab Dedicated and self-hosted customers using CloudConnect are deployed using [Runway](https://docs.runway.gitlab.com/welcome/onboarding/).
Refer to the project documentation on how to add or manage Runway services.

### Deploying in self-hosted environments

Deploying services to self-hosted environments poses challenges as services are not part of the monolith. Currently, Runway does not support self-hosted instances, and Omnibus does not support Python services, so deployment is only possible by users pulling the service image.

#### Image guidelines

1. Use a different user than the root user
1. Configure poetry variables correctly to avoid runtime issues
1. Use [multi-stage Docker builds](https://docs.docker.com/build/building/multi-stage/) images to create lighter images

[Example of image](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/blob/main/Dockerfile#L41-L47)

#### Versioning

Self-hosted customers need to know which version of the service is compatible with their GitLab installation. Python services do not make use of [managed versioning](https://gitlab.com/gitlab-org/release/docs/-/tree/master/components/managed-versioning), so each service needs to handle its versioning and release cuts.

If a service is accessible through cloud-connector, it must adhere to [GitLab Statement Support](https://about.gitlab.com/support/statement-of-support/#version-support), providing stable deployments for the current and previous 2 majors releases of GitLab.

##### Tips

###### Create versions that match GitLab release

When supporting self-hosted deployment, it's important to have a version tag that matches GitLab versions, making it easier
for users to configure the different components of their environment. Add a pipeline to GitLab the GitLab release process
that tags the service repo with the same tag, which will then trigger a pipeline to create an image with the defined tag.

Example: [a pipeline on GitLab](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/aigw-tagging.gitlab-ci.yml) creates a tag on AI Gateway
that [releases a new image](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/.gitlab/ci/build.gitlab-ci.yml?ref_type=heads#L24).

###### Multiple release deployments

Supporting 3 major versions can lead to a confusing codebase due to too many code paths. An alternative to keep support while
allowing code clean ups is to provide deployments for multiple versions of the service. For example, suppose GitLab is on
version `19.5`, this would need three deployments of the service:

- One for service version `17.11`, which provides support for all GitLab `17.x` versions
- One for service version `18.11`, which provides support for all GitLab `18.x` versions
- One for service version `19.5`, which provides support for GitLab versions `19.0`-`19.5`.

Once version 18.0 is released, unused code from versions 17.x can be safely removed, since a legacy deployment will be present.
Then, once version 20.0 is released, and GitLab version 17.x is not supported anymore, the legacy deployment can also be removed.

#### Publishing images

Images must be published in the container registry of the project.

It's also recommend to publish the images on DockerHub. To create an image repository on Docker Hub, create an account with your GitLab handle and create an Access Request to be added to the [GitLab organization](https://hub.docker.com/u/gitlab). Once the image repository is created, make sure the user `gitlabcibuild` has read and write access to the repository.

#### Linux package deployment

To be added.

### Deployment on GitLab Dedicated

Deployment of Python services on GitLab Dedicated is not currently supported
