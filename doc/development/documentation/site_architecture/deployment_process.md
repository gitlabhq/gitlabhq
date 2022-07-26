---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Documentation deployments

The documentation [release process](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/doc/releases.md)
involves:

- Merge requests, to make changes to the `main` and relevant stable branches.
- Pipelines, to build and deploy Docker images to the [`gitlab-docs` container registry](https://gitlab.com/gitlab-org/gitlab-docs/container_registry)
  for the relevant stable branches.
- Docker images used to build and deploy all the online documentation, including stable versions and the latest documentation.

Documentation deployments have dependencies on pipelines and Docker images as follows:

- The latest documentation pipelines and images depend on the stable documentation pipelines and images.
- The Pages deployment pipelines depend on the latest documentation images (which, in turn, depend on the stable
  pipelines and images.)

For general information on using Docker with CI/CD pipelines, see [Docker integration](../../../ci/docker/index.md).

## Stable branches

Stable branches for documentation include the relevant stable branches of all the projects required to publish the entire
documentation suite. For example, the stable version of documentation for version `14.4` includes:

- The [`14.4`](https://gitlab.com/gitlab-org/gitlab-docs/-/tree/14.4) branch of the `gitlab-docs` project.
- The [`14-4-stable-ee`](https://gitlab.com/gitlab-org/gitlab/-/tree/14-4-stable-ee) branch of the `gitlab` project.
- The [`14-4-stable`](https://gitlab.com/gitlab-org/gitlab-runner/-/tree/14-4-stable) branch of the `gitlab-runner` project.
- The [`14-4-stable`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/tree/14-4-stable) branch of the `omnibus-gitlab` project.
- The [`5-4-stable`](https://gitlab.com/gitlab-org/charts/gitlab/-/tree/5-4-stable) branch of the `charts/gitlab` project.
  `charts/gitlab` versions are [mapped](https://docs.gitlab.com/charts/installation/version_mappings.html) to GitLab
  versions.

The Technical Writing team
[creates the stable branch](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/doc/releases.md#create-stable-branch-and-docker-image-for-release)
for the `gitlab-docs` project, which makes use of the stable branches created by other teams.

## Stable documentation

When merge requests are merged that target stable branches of `gitlab-docs`, a pipeline builds
that stable documentation and deploys it to the registry. For example:

- [14.4 merge request pipeline](https://gitlab.com/gitlab-org/gitlab-docs/-/pipelines/394459635).
- [14.3 merge request pipeline](https://gitlab.com/gitlab-org/gitlab-docs/-/pipelines/393774811).
- [14.2 merge request pipeline](https://gitlab.com/gitlab-org/gitlab-docs/-/pipelines/393774758).
- [13.12 merge request pipeline](https://gitlab.com/gitlab-org/gitlab-docs/-/pipelines/395365202).
- [12.10 merge request pipeline](https://gitlab.com/gitlab-org/gitlab-docs/-/pipelines/395365405).

In particular, the [`image:docs-single` job](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/4c18963fe0a414ad62f55b9e18f922588b2dd155/.gitlab-ci.yml#L655) in each pipeline runs automatically.
It takes what is built, and pushes it to the [container registry](https://gitlab.com/gitlab-org/gitlab-docs/container_registry/631635).

```mermaid
graph TD
  A["14.4 MR merged"]
  B["14.3 MR merged"]
  C["14.2 MR merged"]
  D["13.12 MR merged"]
  E["12.10 MR merged"]
  F{{"Container registry on `gitlab-docs` project"}}
  A--"`image:docs-single`<br>job runs and pushes<br>`gitlab-docs:14.4` image"-->F
  B--"`image:docs-single`<br>job runs and pushes<br>`gitlab-docs:14.3` image"-->F
  C--"`image:docs-single`<br>job runs and pushes<br>`gitlab-docs:14.2` image"-->F
  D--"`image:docs-single`<br>job runs and pushes<br>`gitlab-docs:13.12` image"-->F
  E--"`image:docs-single`<br>job runs and pushes<br>`gitlab-docs:12.10` image"-->F
```

### Rebuild stable documentation images

To rebuild any of the stable documentation images, create a [new pipeline](https://gitlab.com/gitlab-org/gitlab-docs/-/pipelines/new)
for the stable branch of the image to rebuild. You might do this:

- To include new documentation changes from an upstream stable branch into a stable version Docker image. For example,
  rebuild the `14.4` Docker image to include changes subsequently merged in the `gitlab` project's
  [`14-4-stable-ee`](https://gitlab.com/gitlab-org/gitlab/-/tree/14-4-stable-ee) branch.
- To incorporate changes made to the `gitlab-docs` project itself to a stable branch. For example:
  - CSS style changes.
  - Changes to the [version menu for a new release](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/doc/releases.md#update-dropdown-for-online-versions).

## Latest documentation

We build a Docker image (tagged `latest`) that contains:

- The latest online version of the documentation.
- The documentation from the stable branches of upstream projects.

The [`image:docs-latest` job](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/4c18963fe0a414ad62f55b9e18f922588b2dd155/.gitlab-ci.yml#L678):

- Pulls the latest documentation from the default branches of the relevant upstream projects.
- Pulls the Docker images previously built by the `image:docs-single` jobs.
- Must be run manually on a scheduled pipeline.

For example, [a pipeline](https://gitlab.com/gitlab-org/gitlab-docs/-/pipelines/399233948) containing the
[`image:docs-latest` job](https://gitlab.com/gitlab-org/gitlab-docs/-/jobs/1733948330):

```mermaid
graph TD
  A["Latest `gitlab`, `gitlab-runner`<br>`omnibus-gitlab`, and `charts`"]
  subgraph "Container registry on `gitlab-docs` project"
    B["14.4 versioned docs<br>`gitlab-docs:14.4`"]
    C["14.3 versioned docs<br>`gitlab-docs:14.3`"]
    D["14.2 versioned docs<br>`gitlab-docs:14.2`"]
    E["13.12 versioned docs<br>`gitlab-docs:13.12`"]
    F["12.10 versioned docs<br>`gitlab-docs:12.10`"]
  end
  G[["Scheduled pipeline<br>`image:docs-latest` job<br>combines all these"]]
  A--"Default branches<br>pulled down"-->G
  B--"`gitlab-docs:14.4` image<br>pulled down"-->G
  C--"`gitlab-docs:14.3` image<br>pulled down"-->G
  D--"`gitlab-docs:14.2` image<br>pulled down"-->G
  E--"`gitlab-docs:13.12` image<br>pulled down"-->G
  F--"`gitlab-docs:12.10` image<br>pulled down"-->G
  H{{"Container registry on gitlab-docs project"}}
  G--"Latest `gitlab-docs:latest` image<br>pushed up"-->H
```

## Documentation Pages deployment

[GitLab Docs](https://docs.gitlab.com) is a [Pages site](../../../user/project/pages/index.md) and documentation updates
for it must be deployed to become available.

The [`pages`](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/4c18963fe0a414ad62f55b9e18f922588b2dd155/.gitlab-ci.yml#L491)
job runs automatically when a pipeline runs on the default branch (`main`).
It runs the necessary commands to combine:

- A very up-to-date build of the `gitlab-docs` site code.
- The latest docs from the default branches of the upstream projects.
- The documentation from `image:docs-latest`.

For example, [a pipeline](https://gitlab.com/gitlab-org/gitlab-docs/-/pipelines/399233948) containing the
[`pages` job](https://gitlab.com/gitlab-org/gitlab-docs/-/jobs/1733948332).

```mermaid
graph LR
  A{{"Container registry on gitlab-docs project"}}
  B[["Scheduled pipeline<br>`pages` and<br>`pages:deploy` job"]]
  C([docs.gitlab.com])
  A--"`gitlab-docs:latest`<br>pulled"-->B
  B--"Unpacked documentation uploaded"-->C
```

## Docker files

The [`dockerfiles` directory](https://gitlab.com/gitlab-org/gitlab-docs/blob/main/dockerfiles/) contains all needed
Dockerfiles to build and deploy <https://docs.gitlab.com>. It is heavily inspired by Docker's
[Dockerfile](https://github.com/docker/docker.github.io/blob/06ed03db13895bfe867761b6fc2ad40acf6026dd/Dockerfile).

| Dockerfile                                                                                                                 | Docker image                  | Description                                                                                                                                                                                                                                                                           |
|:---------------------------------------------------------------------------------------------------------------------------|:------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [`bootstrap.Dockerfile`](https://gitlab.com/gitlab-org/gitlab-docs/blob/main/dockerfiles/bootstrap.Dockerfile)             | `gitlab-docs:bootstrap`       | Contains all the dependencies that are needed to build the website. If the gems are updated and `Gemfile{,.lock}` changes, the image must be rebuilt.                                                                                                                                 |
| [`builder.onbuild.Dockerfile`](https://gitlab.com/gitlab-org/gitlab-docs/blob/main/dockerfiles/builder.onbuild.Dockerfile) | `gitlab-docs:builder-onbuild` | Base image to build the docs website. It uses `ONBUILD` to perform all steps and depends on `gitlab-docs:bootstrap`.                                                                                                                                                                  |
| [`nginx.onbuild.Dockerfile`](https://gitlab.com/gitlab-org/gitlab-docs/blob/main/dockerfiles/nginx.onbuild.Dockerfile)     | `gitlab-docs:nginx-onbuild`   | Base image to use for building documentation archives. It uses `ONBUILD` to perform all required steps to copy the archive, and relies upon its parent `Dockerfile.builder.onbuild` that is invoked when building single documentation archives (see the `Dockerfile` of each branch) |
| [`archives.Dockerfile`](https://gitlab.com/gitlab-org/gitlab-docs/blob/main/dockerfiles/archives.Dockerfile)               | `gitlab-docs:archives`        | Contains all the versions of the website in one archive. It copies all generated HTML files from every version in one location.                                                                                                                                                       |

### How to build the images

Although build images are built automatically via GitLab CI/CD, you can build and tag all tooling images locally:

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
