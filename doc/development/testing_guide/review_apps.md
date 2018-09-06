# Review apps

We currently have review apps available as a manual job in EE pipelines. Here is
[the first implementation](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/6259).

That said, [the Quality team is working](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/6665)
on making Review Apps automatically deployed by each pipeline, both in CE and EE.

## How does it work?

1. On every EE [pipeline][gitlab-pipeline] during the `test` stage, you can
  start the [`review` job][review-job]
1. The `review` job [triggers a pipeline][cng-pipeline] in the
  [`CNG-mirror`][cng-mirror] [^1] project
1. The `CNG-mirror` pipeline creates the Docker images of each component (e.g. `gitlab-rails-ee`,
  `gitlab-shell`, `gitaly` etc.) based on the commit from the
  [GitLab pipeline][gitlab-pipeline] and store them in its
  [registry][cng-mirror-registry]
1. Once all images are built, the review app is deployed using
  [the official GitLab Helm chart][helm-chart] [^2] to the
  [`review-apps-ee` Kubernetes cluster on GCP][review-apps-ee]
  - The actual scripts used to deploy the review app can be found at
    [`scripts/review_apps/review-apps.sh`][review-apps.sh]
  - These scripts are basically
    [our official Auto DevOps scripts][Auto-DevOps.gitlab-ci.yml] where the
    default CNG images are overriden with the images built and stored in the
    [`CNG-mirror` project's registry][cng-mirror-registry]
1. Once the `review` job succeeds, you should be able to use your review app
  thanks to the direct link to it from the MR widget. The default username is
  `root` and its password can be found in the 1Password secure note named
  **gitlab-{ce,ee} review app's root password**.

**Additional notes:**

- The Kubernetes cluster is connected to the `gitlab-ee` project using [GitLab's
  Kubernetes integration][gitlab-k8s-integration]. This basically allows to have
  a link to the review app directly from the merge request widget.
- The manual `stop_review` in the `post-cleanup` stage can be used to stop a
  review app manually, and is also started by GitLab once a branch is deleted
- [TBD] Review apps are cleaned up regularly using a pipeline schedule that runs
  the [`scripts/review_apps/automated_cleanup.rb`][automated_cleanup.rb] script

[^1]: We use the `CNG-mirror` project so that the `CNG`, (**C**loud **N**ative **G**itLab), project's registry is
  not overloaded with a lot of transient Docker images.
[^2]: Since we're using [the official GitLab Helm chart][helm-chart], this means
  you get the a dedicated environment for your branch that's very close to what it
  would look in production

## Frequently Asked Questions

**Will it be too much to trigger CNG image builds on every test run? This could create thousands of unused docker images.**

  > We have to start somewhere and improve later. If we see this getting out of hand, we will revisit.

**How big is the Kubernetes cluster?**

  > The cluster is currently setup with a single pool of preemptible
    nodes, with a minimum of 1 node and a maximum of 30 nodes.

**What are the machine running on the cluster?**

  > We're currently using `n1-standard-4` (4 vCPUs, 15 GB memory) machines.

**How do we secure this from abuse? Apps are open to the world so we need to find a way to limit it to only us.**

  > This won't work for forks. We will add a root password to 1password shared vault.

[gitlab-pipeline]: https://gitlab.com/gitlab-org/gitlab-ee/pipelines/29302122
[review-job]: https://gitlab.com/gitlab-org/gitlab-ee/-/jobs/94294136
[cng-mirror]: https://gitlab.com/gitlab-org/build/CNG-mirror
[cng-pipeline]: https://gitlab.com/gitlab-org/build/CNG-mirror/pipelines/29307727
[cng-mirror-registry]: https://gitlab.com/gitlab-org/build/CNG-mirror/container_registry
[helm-chart]: https://gitlab.com/charts/gitlab/
[review-apps-ee]: https://console.cloud.google.com/kubernetes/clusters/details/us-central1-b/review-apps-ee?project=gitlab-review-apps
[review-apps.sh]: https://gitlab.com/gitlab-org/gitlab-ee/blob/master/scripts/review_apps/review-apps.sh
[automated_cleanup.rb]: https://gitlab.com/gitlab-org/gitlab-ee/blob/master/scripts/review_apps/automated_cleanup.rb
[Auto-DevOps.gitlab-ci.yml]: https://gitlab.com/gitlab-org/gitlab-ci-yml/blob/master/Auto-DevOps.gitlab-ci.yml
[gitlab-k8s-integration]: https://docs.gitlab.com/ee/user/project/clusters/index.html

---

[Return to Testing documentation](index.md)
