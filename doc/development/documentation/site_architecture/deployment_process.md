---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Documentation deployment process

The [`dockerfiles` directory](https://gitlab.com/gitlab-org/gitlab-docs/blob/main/dockerfiles/)
contains all needed Dockerfiles to build and deploy <https://docs.gitlab.com>. It
is heavily inspired by Docker's
[Dockerfile](https://github.com/docker/docker.github.io/blob/06ed03db13895bfe867761b6fc2ad40acf6026dd/Dockerfile).

The following Dockerfiles are used.

| Dockerfile | Docker image | Description |
| ---------- | ------------ | ----------- |
| [`Dockerfile.bootstrap`](https://gitlab.com/gitlab-org/gitlab-docs/blob/main/dockerfiles/Dockerfile.bootstrap) | `gitlab-docs:bootstrap` | Contains all the dependencies that are needed to build the website. If the gems are updated and `Gemfile{,.lock}` changes, the image must be rebuilt. |
| [`Dockerfile.builder.onbuild`](https://gitlab.com/gitlab-org/gitlab-docs/blob/main/dockerfiles/Dockerfile.builder.onbuild) | `gitlab-docs:builder-onbuild` | Base image to build the docs website. It uses `ONBUILD` to perform all steps and depends on `gitlab-docs:bootstrap`. |
| [`Dockerfile.nginx.onbuild`](https://gitlab.com/gitlab-org/gitlab-docs/blob/main/dockerfiles/Dockerfile.nginx.onbuild) | `gitlab-docs:nginx-onbuild` | Base image to use for building documentation archives. It uses `ONBUILD` to perform all required steps to copy the archive, and relies upon its parent `Dockerfile.builder.onbuild` that is invoked when building single documentation archives (see the `Dockerfile` of each branch. |
| [`Dockerfile.archives`](https://gitlab.com/gitlab-org/gitlab-docs/blob/main/dockerfiles/Dockerfile.archives) | `gitlab-docs:archives` | Contains all the versions of the website in one archive. It copies all generated HTML files from every version in one location. |

## How to build the images

Although build images are built automatically via GitLab CI/CD, you can build
and tag all tooling images locally:

1. Make sure you have [Docker installed](https://docs.docker.com/install/).
1. Make sure you're in the `dockerfiles/` directory of the `gitlab-docs` repository.
1. Build the images:

   ```shell
   docker build -t registry.gitlab.com/gitlab-org/gitlab-docs:bootstrap -f Dockerfile.bootstrap ../
   docker build -t registry.gitlab.com/gitlab-org/gitlab-docs:builder-onbuild -f Dockerfile.builder.onbuild ../
   docker build -t registry.gitlab.com/gitlab-org/gitlab-docs:nginx-onbuild -f Dockerfile.nginx.onbuild ../
   ```

For each image, there's a manual job under the `images` stage in
[`.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab-docs/blob/main/.gitlab-ci.yml) which can be invoked at any time.

## Update an old Docker image with new upstream docs content

If there are any changes to any of the stable branches of the products that are
not included in the single Docker image, just rerun the pipeline (`https://gitlab.com/gitlab-org/gitlab-docs/pipelines/new`)
for the version in question.

## Porting new website changes to old versions

WARNING:
Porting changes to older branches can have unintended effects as we're constantly
changing the backend of the website. Use only when you know what you're doing
and make sure to test locally.

The website keeps changing and being improved. In order to consolidate
those changes to the stable branches, we'd need to pick certain changes
from time to time.

If this is not possible or there are many changes, merge main into them:

```shell
git branch 12.0
git fetch origin main
git merge origin/main
```
