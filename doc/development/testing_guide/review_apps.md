# Review Apps

Review Apps are automatically deployed by each pipeline, both in
[CE](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/22010) and
[EE](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/6665).

## How does it work?

1. On every [pipeline][gitlab-pipeline] during the `test` stage, the
  [`review` job][review-job] is automatically started.
1. The `review` job [triggers a pipeline][cng-pipeline] in the
  [`CNG-mirror`][cng-mirror] project.
    - We use the `CNG-mirror` project so that the `CNG`, (**C**loud **N**ative
      **G**itLab), project's registry is not overloaded with a lot of transient
      Docker images.
1. The `CNG-mirror` pipeline creates the Docker images of each component (e.g.
  `gitlab-rails-ee`, `gitlab-shell`, `gitaly` etc.) based on the commit from the
  [GitLab pipeline][gitlab-pipeline] and store them in its
  [registry][cng-mirror-registry].
1. Once all images are built, the Review App is deployed using
  [the official GitLab Helm chart][helm-chart] to the
  [`review-apps-ee` Kubernetes cluster on GCP][review-apps-ee]
    - The actual scripts used to deploy the Review App can be found at
      [`scripts/review_apps/review-apps.sh`][review-apps.sh]
    - These scripts are basically
      [our official Auto DevOps scripts][Auto-DevOps.gitlab-ci.yml] where the
      default CNG images are overridden with the images built and stored in the
      [`CNG-mirror` project's registry][cng-mirror-registry].
    - Since we're using [the official GitLab Helm chart][helm-chart], this means
      you get a dedicated environment for your branch that's very close to what it
      would look in production.
1. Once the `review` job succeeds, you should be able to use your Review App
  thanks to the direct link to it from the MR widget. The default username is
  `root` and its password can be found in the 1Password secure note named
  **gitlab-{ce,ee} Review App's root password** (note that there's currently
  [a bug where the default password seems to be overridden][password-bug]).

**Additional notes:**

- The Kubernetes cluster is connected to the `gitlab-{ce,ee}` projects using
  [GitLab's Kubernetes integration][gitlab-k8s-integration]. This basically
  allows to have a link to the Review App directly from the merge request widget.
- The manual `stop_review` in the `test` stage can be used to stop a Review App
  manually, and is also started by GitLab once a branch is deleted.
- Review Apps are cleaned up regularly using a pipeline schedule that runs
  the [`scripts/review_apps/automated_cleanup.rb`][automated_cleanup.rb] script.
- If the Review App deployment fails, you can simply retry it (there's no need
  to run the `stop_review` job first).
- If you're unable to log in using the `root` username and password, you may
  encounter [this bug][password-bug]. Stop the Review App via the `stop_review`
  manual job and then retry the `review` job to redeploy the Review App.

## Frequently Asked Questions

**Isn't it too much to trigger CNG image builds on every test run? This creates
thousands of unused Docker images.**

  > We have to start somewhere and improve later. Also, we're using the
  CNG-mirror project to store these Docker images so that we can just wipe out
  the registry at some point, and use a new fresh, empty one.

**How big are the Kubernetes clusters (`review-apps-ce` and `review-apps-ee`)?**

  > The clusters are currently set up with a single pool of preemptible nodes,
  with a minimum of 1 node and a maximum of 100 nodes.

**What are the machine running on the cluster?**

  > We're currently using `n1-standard-4` (4 vCPUs, 15 GB memory) machines.

**How do we secure this from abuse? Apps are open to the world so we need to
find a way to limit it to only us.**

  > This isn't enabled for forks.

[gitlab-pipeline]: https://gitlab.com/gitlab-org/gitlab-ce/pipelines/35850709
[review-job]: https://gitlab.com/gitlab-org/gitlab-ce/-/jobs/118076368
[cng-mirror]: https://gitlab.com/gitlab-org/build/CNG-mirror
[cng-pipeline]: https://gitlab.com/gitlab-org/build/CNG-mirror/pipelines/35883435
[cng-mirror-registry]: https://gitlab.com/gitlab-org/build/CNG-mirror/container_registry
[helm-chart]: https://gitlab.com/charts/gitlab/
[review-apps-ee]: https://console.cloud.google.com/kubernetes/clusters/details/us-central1-b/review-apps-ee?project=gitlab-review-apps
[review-apps.sh]: https://gitlab.com/gitlab-org/gitlab-ee/blob/master/scripts/review_apps/review-apps.sh
[automated_cleanup.rb]: https://gitlab.com/gitlab-org/gitlab-ee/blob/master/scripts/review_apps/automated_cleanup.rb
[Auto-DevOps.gitlab-ci.yml]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml
[gitlab-k8s-integration]: https://docs.gitlab.com/ee/user/project/clusters/index.html
[password-bug]: https://gitlab.com/gitlab-org/gitlab-ce/issues/53621

---

[Return to Testing documentation](index.md)
