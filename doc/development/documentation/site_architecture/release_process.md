---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Docs monthly release process

When a new GitLab version is released on the 22nd, we need to create the respective
single Docker image, and update some files so that the dropdown works correctly.

## 1. Add the chart version

Since the charts use a different version number than all the other GitLab
products, we need to add a
[version mapping](https://docs.gitlab.com/charts/installation/version_mappings.html):

The charts stable branch is not created automatically like the other products.
There's an [issue to track this](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1442).
It is usually created on the 21st or the 22nd.

To add a new charts version:

1. Make sure you're in the root path of the `gitlab-docs` repository.
1. Open `content/_data/chart_versions.yaml` and add the new stable branch version using the
   version mapping. Note that only the `major.minor` version is needed.
1. Create a new merge request and merge it.

TIP: **Tip:**
It can be handy to create the future mappings since they are pretty much known.
In that case, when a new GitLab version is released, you don't have to repeat
this first step.

## 2. Create an image for a single version

The single docs version must be created before the release merge request, but
this needs to happen when the stable branches for all products have been created.

1. Make sure you're in the root path of the `gitlab-docs` repository.
1. Run the Rake task to create the single version:

   ```shell
   ./bin/rake "release:single[12.0]"
   ```

    A new `Dockerfile.12.0` should have been created and `.gitlab-ci.yml` should
    have the branches variables updated into a new branch. They are automatically
    committed.

1. Push the newly created branch, but **don't create a merge request**.
   After you push, the `image:docs-single` job creates a new Docker image
   tagged with the branch name you created in the first step. In the end, the
   image is uploaded in the [Container Registry](https://gitlab.com/gitlab-org/gitlab-docs/container_registry)
   and it is listed under the `registry` environment folder at
   `https://gitlab.com/gitlab-org/gitlab-docs/-/environments/folders/registry` (must
   have developer access).

Optionally, you can test locally by building the image and running it:

```shell
docker build -t docs:12.0 -f Dockerfile.12.0 .
docker run -it --rm -p 4000:4000 docs:12.0
```

Visit `http://localhost:4000/12.0/` to see if everything works correctly.

## 3. Create the release merge request

NOTE: **Note:**
To be [automated](https://gitlab.com/gitlab-org/gitlab-docs/-/issues/750).

Now it's time to create the monthly release merge request that adds the new
version and rotates the old one:

1. Make sure you're in the root path of the `gitlab-docs` repository.
1. Create a branch `release-X-Y`:

   ```shell
   git checkout master
   git checkout -b release-12-0
   ```

1. **Rotate the online and offline versions:**

   At any given time, there are 4 browsable online versions: one pulled from
   the upstream master branches (docs for GitLab.com) and the three latest
   stable versions.

   Edit `content/_data/versions.yaml` and rotate the versions to reflect the
   new changes:

   - `online`: The 3 latest stable versions.
   - `offline`: All the previous versions offered as an offline archive.

1. **Update the `:latest` and `:archives` Docker images:**

   The following two Dockerfiles need to be updated:

   1. `dockerfiles/Dockerfile.archives` - Add the latest version at the top of
      the list.
   1. `Dockerfile.master` - Rotate the versions (oldest gets removed and latest
       is added at the top of the list).

1. In the end, there should be four files in total that have changed.
   Commit and push to create the merge request using the "Release" template:

   ```shell
   git add content/ Dockerfile.master dockerfiles/Dockerfile.archives
   git commit -m "Release 12.0"
   git push origin release-12-0
   ```

## 4. Update the dropdown for all online versions

The versions dropdown is in a way "hardcoded". When the site is built, it looks
at the contents of `content/_data/versions.yaml` and based on that, the dropdown
is populated. Older branches have different content, which means the
dropdown list is one or more releases behind. Remember that the new changes of
the dropdown are included in the unmerged `release-X-Y` branch.

The content of `content/_data/versions.yaml` needs to change for all online
versions (stable branches `X.Y` of the `gitlab-docs` project):

1. Run the Rake task that creates all the respective merge requests needed to
   update the dropdowns. Set these to automatically be merged when their
   pipelines succeed:

   NOTE: **Note:**
   The `release-X-Y` branch needs to be present locally,
   and you need to have switched to it, otherwise the Rake task fails.

   ```shell
   git checkout release-X-Y
   ./bin/rake release:dropdowns
   ```

1. [Visit the merge requests page](https://gitlab.com/gitlab-org/gitlab-docs/-/merge_requests?label_name%5B%5D=release)
   to check that their pipelines pass, and once all are merged, proceed to the
   following and final step.

TIP: **Tip:**
In case a pipeline fails, see [troubleshooting](#troubleshooting).

## 5. Merge the release merge request

The dropdown merge requests should have now been merged into their respective
version (stable `X.Y` branch), which triggers another pipeline. At this point,
you need to only babysit the pipelines and make sure they don't fail:

1. Check the [pipelines page](https://gitlab.com/gitlab-org/gitlab-docs/pipelines)
   and make sure all stable branches have green pipelines.
1. After all the pipelines of the online versions succeed, merge the release merge request.
1. Finally, run the
   [`Build docker images weekly` pipeline](https://gitlab.com/gitlab-org/gitlab-docs/pipeline_schedules)
   that builds the `:latest` and `:archives` Docker images.

Once the scheduled pipeline succeeds, the docs site is deployed with all
new versions online.

## Troubleshooting

Releasing a new version is a long process that involves many moving parts.

### `test_internal_links_and_anchors` failing on dropdown merge requests

DANGER: **Deprecated:**
We now pin versions in the `.gitlab-ci.yml` of the respective branch,
so the steps below are deprecated.

When [updating the dropdown for the stable versions](#4-update-the-dropdown-for-all-online-versions),
there may be cases where some links might fail. The process of how the
dropdown MRs are created have a caveat, and that is that the tests run by
pulling the master branches of all products, instead of the respective stable
ones.

In a real world scenario, the [Update 12.2 dropdown to match that of 12.4](https://gitlab.com/gitlab-org/gitlab-docs/-/merge_requests/604)
merge request failed because of the [`test_internal_links_and_anchors` test](https://gitlab.com/gitlab-org/gitlab-docs/-/jobs/328042431).

This happened because there has been a rename of a product (`gitlab-monitor` to `gitlab-exporter`)
and the old name was still referenced in the 12.2 docs. If the respective stable
branches for 12.2 were used, this wouldn't have failed, but as we can see from
the [`compile_dev` job](https://gitlab.com/gitlab-org/gitlab-docs/-/jobs/328042427),
the `master` branches were pulled.

To fix this, re-run the pipeline (`https://gitlab.com/gitlab-org/gitlab-docs/pipelines/new`)
for the `update-12-2-for-release-12-4` branch, by including the following environment variables:

- `BRANCH_CE` set to `12-2-stable`
- `BRANCH_EE` set to `12-2-stable-ee`
- `BRANCH_OMNIBUS` set to `12-2-stable`
- `BRANCH_RUNNER` set to `12-2-stable`
- `BRANCH_CHARTS` set to `2-2-stable`

This should make the MR pass.
