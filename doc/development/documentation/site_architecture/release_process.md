---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Monthly release process

When a new GitLab version is released on the 22nd, we release version-specific published
documentation for the new version.

We complete the process as soon as possible after the GitLab version is announced. The result is:

- The [online published documentation](https://docs.gitlab.com) includes:
  - The three most recent minor releases of the current major version. For example 13.9, 13.8, and
    13.7.
  - The most recent minor releases of the last two major versions. For example 12.10, and 11.11.
- Documentation updates after the 22nd are for the next release. The versions drop down
  should have the current milestone with `-pre` appended to it, for example `13.10-pre`.

Each documentation release:

- Has a dedicated branch, named in the format `XX.yy`.
- Has a Docker image that contains a build of that branch.

For example:

- For [GitLab 13.9](https://docs.gitlab.com/13.9/index.html), the
  [stable branch](https://gitlab.com/gitlab-org/gitlab-docs/-/tree/13.9) and Docker image:
  [`registry.gitlab.com/gitlab-org/gitlab-docs:13.9`](https://gitlab.com/gitlab-org/gitlab-docs/container_registry/631635).
- For [GitLab 13.8](https://docs.gitlab.com/13.8/index.html), the
  [stable branch](https://gitlab.com/gitlab-org/gitlab-docs/-/tree/13.8) and Docker image:
  [`registry.gitlab.com/gitlab-org/gitlab-docs:13.8`](https://gitlab.com/gitlab-org/gitlab-docs/container_registry/631635).

## Recommended timeline

To minimize problems during the documentation release process, use the following timeline:

- Before the 20nd of the month:

  [Add the charts version](#add-chart-version), so that the documentation is built using the
  [version of the charts project that maps to](https://docs.gitlab.com/charts/installation/version_mappings.html)
  the GitLab release. This step may have been completed already.

- On or near the 20th of the month:

  1. [Create a stable branch and Docker image](#create-stable-branch-and-docker-image-for-release) for
     the new version.
  1. [Create a release merge request](#create-release-merge-request) for the new version, which
     updates the version dropdown menu for the current documentation and adds the release to the
     Docker configuration. For example, the
     [release merge request for 13.9](https://gitlab.com/gitlab-org/gitlab-docs/-/merge_requests/1555).
  1. [Update the three online versions](#update-dropdown-for-online-versions), so that they display the new release on their
     version dropdown menus.

- On the 22nd of the month:

  [Merge the release merge requests and run the necessary Docker image builds](#merge-merge-requests-and-run-docker-image-builds).

## Add chart version

To add a new charts version for the release:

1. Make sure you're in the root path of the `gitlab-docs` repository.
1. Open `content/_data/chart_versions.yaml` and add the new stable branch version using the
   [version mapping](https://docs.gitlab.com/charts/installation/version_mappings.html). Only the
   `major.minor` version is needed.
1. Create a new merge request and merge it.

NOTE:
If you have time, add anticipated future mappings to `content/_data/chart_versions.yaml`. This saves
a step for the next GitLab release.

## Create stable branch and Docker image for release

To create a stable branch and Docker image for the release:

1. Make sure you're in the root path of the `gitlab-docs` repository.
1. Run the Rake task to create the single version. For example, to create the 13.9 release branch
   and perform others tasks:

   ```shell
   ./bin/rake "release:single[13.9]"
   ```

    A branch for the release is created, a new `Dockerfile.13.9` is created, and `.gitlab-ci.yml`
    has branches variables updated into a new branch. These files are automatically committed.

1. Push the newly created branch, but **don't create a merge request**. After you push, the
   `image:docs-single` job creates a new Docker image tagged with the name of the branch you created
   earlier. You can see the Docker image in the `registry` environment at
   <https://gitlab.com/gitlab-org/gitlab-docs/-/environments/folders/registry>.

For example, see [the 13.9 release pipeline](https://gitlab.com/gitlab-org/gitlab-docs/-/pipelines/260288747).

Optionally, you can test locally by:

1. Building the image and running it. For example, for GitLab 13.9 documentation:

   ```shell
   docker build -t docs:13.9 -f Dockerfile.13.9 .
   docker run -it --rm -p 4000:4000 docs:13.9
   ```

1. Visiting <http://localhost:4000/13.9/> to see if everything works correctly.

## Create release merge request

NOTE:
An [epic is open](https://gitlab.com/groups/gitlab-org/-/epics/4361) to automate this step.

To create the release merge request for the release:

1. Make sure you're in the root path of the `gitlab-docs` repository.
1. Create a branch `release-X-Y`. For example:

   ```shell
   git checkout master
   git checkout -b release-13-9
   ```

1. Edit `content/_data/versions.yaml` and update the lists of versions to reflect the new release:

   - Add the latest version to the `online:` section.
   - Move the oldest version in `online:` to the `offline:` section. There should now be three
     versions in `online:`.

1. Update these Dockerfiles:

   - `dockerfiles/Dockerfile.archives`: Add the latest version to the top of the list.
   - `Dockerfile.master`: Remove the oldest version, and add the newest version to the
     top of the list.

1. Commit and push to create the merge request. For example:

   ```shell
   git add content/ Dockerfile.master dockerfiles/Dockerfile.archives
   git commit -m "Release 13.9"
   git push origin release-13-9
   ```

Do not merge the release merge request yet.

## Update dropdown for online versions

To update `content/_data/versions.yaml` for all online versions (stable branches `X.Y` of the
`gitlab-docs` project). For example:

- The merge request to [update the 13.9 version dropdown menu for the 13.9 release](https://gitlab.com/gitlab-org/gitlab-docs/-/merge_requests/1556).
- The merge request to [update the 13.8 version dropdown menu for the 13.9 release](https://gitlab.com/gitlab-org/gitlab-docs/-/merge_requests/1557).
- The merge request to [update the 13.7 version dropdown menu for the 13.9 release](https://gitlab.com/gitlab-org/gitlab-docs/-/merge_requests/1558).

1. Run the Rake task that creates all of the necessary merge requests to update the dropdowns. For
   example, for the 13.9 release:

   ```shell
   git checkout release-13-9
   ./bin/rake release:dropdowns
   ```

1. [Visit the merge requests page](https://gitlab.com/gitlab-org/gitlab-docs/-/merge_requests?label_name%5B%5D=release)
   to check that their pipelines pass.

Do not merge these merge requests yet.

## Merge merge requests and run Docker image builds

The merge requests for the dropdowns should now all be merged into their respective stable branches.
Each merge triggers a new pipeline for each stable branch. Wait for the stable branch pipelines to
complete, then:

1. Check the [pipelines page](https://gitlab.com/gitlab-org/gitlab-docs/pipelines)
   and make sure all stable branches have green pipelines.
1. After all the pipelines succeed:
   1. Merge all of the [dropdown merge requests](#update-dropdown-for-online-versions).
   1. Merge the [release merge request](#create-release-merge-request).
1. Finally, run the
   [`Build docker images weekly` pipeline](https://gitlab.com/gitlab-org/gitlab-docs/pipeline_schedules)
   that builds the `:latest` and `:archives` Docker images.

As the last step in the scheduled pipeline, the documentation site deploys with all new versions.
