# GitLab Docs monthly release process

The [`dockerfiles` directory](https://gitlab.com/gitlab-org/gitlab-docs/blob/master/dockerfiles/)
contains all needed Dockerfiles to build and deploy the versioned website. It
is heavily inspired by Docker's
[Dockerfile](https://github.com/docker/docker.github.io/blob/06ed03db13895bfe867761b6fc2ad40acf6026dd/Dockerfile).

The following Dockerfiles are used.

| Dockerfile | Docker image | Description |
| ---------- | ------------ | ----------- |
| [`Dockerfile.bootstrap`](https://gitlab.com/gitlab-org/gitlab-docs/blob/master/dockerfiles/Dockerfile.bootstrap) | `gitlab-docs:bootstrap` | Contains all the dependencies that are needed to build the website. If the gems are updated and `Gemfile{,.lock}` changes, the image must be rebuilt. |
| [`Dockerfile.builder.onbuild`](https://gitlab.com/gitlab-org/gitlab-docs/blob/master/dockerfiles/Dockerfile.builder.onbuild) | `gitlab-docs:builder-onbuild` | Base image to build the docs website. It uses `ONBUILD` to perform all steps and depends on `gitlab-docs:bootstrap`. |
| [`Dockerfile.nginx.onbuild`](https://gitlab.com/gitlab-org/gitlab-docs/blob/master/dockerfiles/Dockerfile.nginx.onbuild) | `gitlab-docs:nginx-onbuild` | Base image to use for building documentation archives. It uses `ONBUILD` to perform all required steps to copy the archive, and relies upon its parent `Dockerfile.builder.onbuild` that is invoked when building single documentation achives (see the `Dockerfile` of each branch. |
| [`Dockerfile.archives`](https://gitlab.com/gitlab-org/gitlab-docs/blob/master/dockerfiles/Dockerfile.archives) | `gitlab-docs:archives` | Contains all the versions of the website in one archive. It copies all generated HTML files from every version in one location. |

## How to build the images

Although build images are built automatically via GitLab CI/CD, you can build
and tag all tooling images locally:

1. Make sure you have [Docker installed](https://docs.docker.com/install/).
1. Make sure you're on the `dockerfiles/` directory of the `gitlab-docs` repo.
1. Build the images:

   ```sh
   docker build -t registry.gitlab.com/gitlab-org/gitlab-docs:bootstrap -f Dockerfile.bootstrap ../
   docker build -t registry.gitlab.com/gitlab-org/gitlab-docs:builder-onbuild -f Dockerfile.builder.onbuild ../
   docker build -t registry.gitlab.com/gitlab-org/gitlab-docs:nginx-onbuild -f Dockerfile.nginx.onbuild ../
   ```

For each image, there's a manual job under the `images` stage in
[`.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab-docs/blob/master/.gitlab-ci.yml) which can be invoked at will.

## Monthly release process

When a new GitLab version is released on the 22nd, we need to create the respective
single Docker image, and update some files so that the dropdown works correctly.

### 1. Add the chart version

Since the charts use a different version number than all the other GitLab
products, we need to add a
[version mapping](https://docs.gitlab.com/charts/installation/version_mappings.html):

1. Check that there is a [stable branch created](https://gitlab.com/gitlab-org/charts/gitlab/-/branches)
   for the new chart version. If you're unsure or can't find it, drop a line in
   the `#g_delivery` channel.
1. Make sure you're on the root path of the `gitlab-docs` repo.
1. Open `content/_data/chart_versions.yaml` and add the new stable branch version using the
   version mapping. Note that only the `major.minor` version is needed.
1. Create a new merge request and merge it.

TIP: **Tip:**
It can be handy to create the future mappings since they are pretty much known.
In that case, when a new GitLab version is released, you don't have to repeat
this first step.

### 2. Create an image for a single version

The single docs version must be created before the release merge request, but
this needs to happen when the stable branches for all products have been created.

1. Make sure you're on the root path of the `gitlab-docs` repo.
1. Run the raketask to create the single version:

    ```sh
    ./bin/rake "release:single[12.0]"
    ```

    A new `Dockerfile.12.0` should have been created and committed to a new branch.

1. Push the newly created branch, but **don't create a merge request**.
   Once you push, the `image:docker-singe` job will create a new Docker image
   tagged with the branch name you created in the first step. In the end, the
   image will be uploaded in the [Container Registry](https://gitlab.com/gitlab-org/gitlab-docs/container_registry)
   and it will be listed under the
   [`registry` environment folder](https://gitlab.com/gitlab-org/gitlab-docs/environments/folders/registry).

Optionally, you can test locally by building the image and running it:

```sh
docker build -t docs:12.0 -f Dockerfile.12.0 .
docker run -it --rm -p 4000:4000 docs:12.0
```

Visit `http://localhost:4000/12.0/` to see if everything works correctly.

### 3. Create the release merge request

Now it's time to create the monthly release merge request that adds the new
version and rotates the old one:

1. Make sure you're on the root path of the `gitlab-docs` repo.
1. Create a branch `release-X-Y`:

   ```sh
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

1. **Add the new offline version in the 404 page redirect script:**

   Since we're deprecating the oldest version each month, we need to redirect
   those URLs in order not to create [404 entries](https://gitlab.com/gitlab-org/gitlab-docs/issues/221).
   There's a temporary hack for now:

   1. Edit `content/404.html`, making sure all offline versions under
      `content/_data/versions.yaml` are in the JavaScript snippet at the end of
      the document.

1. **Update the `:latest` and `:archives` Docker images:**

   The following two Dockerfiles need to be updated:

   1. `dockerfiles/Dockerfile.archives` - Add the latest version at the top of
      the list.
   1. `Dockerfile.master` - Rotate the versions (oldest gets removed and latest
       is added at the top of the list).

1. In the end, there should be four files in total that have changed.
   Commit and push to create the merge request using the "Release" template:

   ```sh
   git add content/ Dockerfile.master dockerfiles/Dockerfile.archives
   git commit -m "Release 12.0"
   git push origin release-12-0
   ```

### 4. Update the dropdown for all online versions

The versions dropdown is in a way "hardcoded". When the site is built, it looks
at the contents of `content/_data/versions.yaml` and based on that, the dropdown
is populated. So, older branches will have different content, which means the
dropdown will be one or more releases behind. Remember that the new changes of
the dropdown are included in the unmerged `release-X-Y` branch.

The content of `content/_data/versions.yaml` needs to change for all online
versions:

1. Before creating the merge request, [disable the scheduled pipeline](https://gitlab.com/gitlab-org/gitlab-docs/pipeline_schedules/228/edit)
   by unchecking the "Active" option. Since all steps must run in sequence, we need
   to do this to avoid race conditions in the event some previous versions are
   updated before the release merge request is merged.
1. Run the raketask that will create all the respective merge requests needed to
   update the dropdowns and will be set to automatically be merged when their
   pipelines succeed. The `release-X-Y` branch needs to be present locally,
   otherwise the raketask will fail:

   ```sh
   ./bin/rake release:dropdowns
   ```

Once all are merged, proceed to the following and final step.

TIP: **Tip:**
In case a pipeline fails, see [troubleshooting](#troubleshooting).

### 5. Merge the release merge request

The dropdown merge requests should have now been merged into their respective
version (stable branch), which will trigger another pipeline. At this point,
you need to only babysit the pipelines and make sure they don't fail:

1. Check the [pipelines page](https://gitlab.com/gitlab-org/gitlab-docs/pipelines)
   and make sure all stable branches have green pipelines.
1. After all the pipelines of the online versions succeed, merge the release merge request.
1. Finally, re-activate the [scheduled pipeline](https://gitlab.com/gitlab-org/gitlab-docs/pipeline_schedules/228/edit),
   save it, and hit the play button to get it started.

Once the scheduled pipeline succeeds, the docs site will be deployed with all
new versions online.

## Update an old Docker image with new upstream docs content

If there are any changes to any of the stable branches of the products that are
not included in the single Docker image, just
[rerun the pipeline](https://gitlab.com/gitlab-org/gitlab-docs/pipelines/new)
for the version in question.

## Porting new website changes to old versions

CAUTION: **Warning:**
Porting changes to older branches can have unintended effects as we're constantly
changing the backend of the website. Use only when you know what you're doing
and make sure to test locally.

The website will keep changing and being improved. In order to consolidate
those changes to the stable branches, we'd need to pick certain changes
from time to time.

If this is not possible or there are many changes, merge master into them:

```sh
git branch 12.0
git fetch origin master
git merge origin/master
```

## Troubleshooting

Releasing a new version is a long process that involves many moving parts.

### `test_internal_links_and_anchors` failing on dropdown merge requests

When [updating the dropdown for the stable versions](#4-update-the-dropdown-for-all-online-versions),
there may be cases where some links might fail. The process of how the
dropdown MRs are created have a caveat, and that is that the tests run by
pulling the master branches of all products, instead of the respective stable
ones.

In a real world scenario, the [Update 12.2 dropdown to match that of 12.4](https://gitlab.com/gitlab-org/gitlab-docs/merge_requests/604)
merge request failed because of the [`test_internal_links_and_anchors` test](https://gitlab.com/gitlab-org/gitlab-docs/-/jobs/328042431).

This happened because there has been a rename of a product (`gitlab-monitor` to `gitlab-exporter`)
and the old name was still referenced in the 12.2 docs. If the respective stable
branches for 12.2 were used, this wouldn't have failed, but as we can see from
the [`compile_dev` job](https://gitlab.com/gitlab-org/gitlab-docs/-/jobs/328042427),
the `master` branches were pulled.

To fix this, you need to [re-run the pipeline](https://gitlab.com/gitlab-org/gitlab-docs/pipelines/new)
for the `update-12-2-for-release-12-4` branch, by including the following environment variables:

- `BRANCH_CE` set to `12-2-stable`
- `BRANCH_EE` set to `12-2-stable-ee`
- `BRANCH_OMNIBUS` set to `12-2-stable`
- `BRANCH_RUNNER` set to `12-2-stable`
- `BRANCH_CHARTS` set to `2-2-stable`

This should make the MR pass.
