---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
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

The following job can be used to deploy the image. Note that PyPI uses [trusted publishers](https://docs.pypi.org/trusted-publishers/), no keys are necessary when the CI pipeline is configured.

```yaml
deploy:
  stage: deploy
  image: python:3.12
  script:
    - poetry --build publish
  rules:
    - if: $CI_COMMIT_TAG =~ /^v-/
```

## Python Services

### Runway deployment for .com

Services for GitLab.com, GitLab Dedicated and self-hosted customers using CloudConnect are deployed using [Runway](https://docs.runway.gitlab.com/welcome/onboarding/).
Please refer to the project documentation on how to add or manage Runway services.

### Deploying in self-hosted environments

Deploying services to self-hosted environments poses challenges as services are not part of the monolith. Currently, Runway does not support self-hosted instances, and Omnibus does not support Python services, so deployment is only possible by users pulling the service image.

#### Image guidelines

1. Use a different user than the root user
1. Configure poetry variables correctly to avoid runtime issues
1. Use [multi-stage Docker builds](https://docs.docker.com/build/building/multi-stage/) images to create lighter images

[Example of image](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/blob/main/Dockerfile#L41-L47)

#### Versioning

Self-hosted customers need to know which version of the service is compatible with their GitLab installation. Python services do not make use of [managed versioning](https://gitlab.com/gitlab-org/release/docs/-/tree/master/components/managed-versioning), so each service needs to handle its versioning and release cuts.

Per convention, once GitLab creates a new release, it can tag the service repo with a new tag named `self-hosted-<gitlab-version>`. An image with that tag is created, as [seen on AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/.gitlab/ci/build.gitlab-ci.yml?ref_type=heads#L9). It's important that we have a version tag that matches GitLab versions, making it easier for users to deploy the full environment.

#### Publishing images

Images must be published in the container registry of the project.

It's also recommend to publish the images on DockerHub. To create an image repository on Docker Hub, create an account with your GitLab handle and create an Access Request to be added to the [GitLab organization](https://hub.docker.com/u/gitlab). Once the image repository is created, make sure the user `gitlabcibuild` has read and write access to the repository.

#### Linux package deployment

To be added.

### Deployment on GitLab Dedicated

Deployment of Python services on GitLab Dedicated is not currently supported
