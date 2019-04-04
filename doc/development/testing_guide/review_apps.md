# Review Apps

Review Apps are automatically deployed by each pipeline, both in
[CE](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/22010) and
[EE](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/6665).

## How does it work?

### CD/CD architecture diagram

![Review Apps CI/CD architecture](img/review_apps_cicd_architecture.png)

<details>
<summary>Show mermaid source</summary>
<pre>
graph TD
    B1 -.->|2. once gitlab:assets:compile is done,<br />triggers a CNG-mirror pipeline and wait for it to be done| A2
    C1 -.->|2. once review-build-cng is done,<br />Helm deploys the Review App using the Cloud<br/>Native images built by the CNG-mirror pipeline| A3

subgraph gitlab-ce/ee `test` stage
    A1[gitlab:assets:compile]
    B1[review-build-cng] -->|1. wait for| A1
    C1[review-deploy] -->|1. wait for| B1
    D1[review-qa-smoke] -->|1. wait for| C1
    D1[review-qa-smoke] -.->|2. once review-deploy is done| E1>gitlab-qa runs the smoke<br/>suite against the Review App]
    end

subgraph CNG-mirror pipeline
    A2>Cloud Native images are built];
    end

subgraph GCP `gitlab-review-apps` project
    A3>"Cloud Native images are deployed to the<br />`review-apps-ce` or `review-apps-ee` Kubernetes (GKE) cluster"];
    end
</pre>
</details>

### Detailed explanation

1. On every [pipeline][gitlab-pipeline] during the `test` stage, the
  [`review-build-cng`][review-build-cng] and
  [`review-deploy`][review-deploy] jobs are automatically started.
    - The [`review-deploy`][review-deploy] job waits for the
      [`review-build-cng`][review-build-cng] job to finish.
    - The [`review-build-cng`][review-build-cng] job waits for the
      [`gitlab:assets:compile`][gitlab:assets:compile] job to finish since the
      [`CNG-mirror`][cng-mirror] pipeline triggered in the following step depends on it.
1. Once the [`gitlab:assets:compile`][gitlab:assets:compile] job is done,
  [`review-build-cng`][review-build-cng] [triggers a pipeline][cng-pipeline]
  in the [`CNG-mirror`][cng-mirror] project.
    - The [`CNG-mirror`][cng-pipeline] pipeline creates the Docker images of
      each component (e.g. `gitlab-rails-ee`, `gitlab-shell`, `gitaly` etc.)
      based on the commit from the [GitLab pipeline][gitlab-pipeline] and store
      them in its [registry][cng-mirror-registry].
    - We use the [`CNG-mirror`][cng-mirror] project so that the `CNG`, (**C**loud
      **N**ative **G**itLab), project's registry is not overloaded with a
      lot of transient Docker images.
1. Once the [`review-build-cng`][review-build-cng] job is done, the
  [`review-deploy`][review-deploy] job deploys the Review App using
  [the official GitLab Helm chart][helm-chart] to the
  [`review-apps-ce`][review-apps-ce] / [`review-apps-ee`][review-apps-ee]
  Kubernetes cluster on GCP.
    - The actual scripts used to deploy the Review App can be found at
      [`scripts/review_apps/review-apps.sh`][review-apps.sh].
    - These scripts are basically
      [our official Auto DevOps scripts][Auto-DevOps.gitlab-ci.yml] where the
      default CNG images are overridden with the images built and stored in the
      [`CNG-mirror` project's registry][cng-mirror-registry].
    - Since we're using [the official GitLab Helm chart][helm-chart], this means
      you get a dedicated environment for your branch that's very close to what
      it would look in production.
1. Once the [`review-deploy`][review-deploy] job succeeds, you should be able to
  use your Review App thanks to the direct link to it from the MR widget. To log
  into the Review App, see "Log into my Review App?" below.

**Additional notes:**

- The Kubernetes cluster is connected to the `gitlab-{ce,ee}` projects using
  [GitLab's Kubernetes integration][gitlab-k8s-integration]. This basically
  allows to have a link to the Review App directly from the merge request
  widget.
- If the Review App deployment fails, you can simply retry it (there's no need
  to run the [`review-stop`][gitlab-ci-yml] job first).
- The manual [`review-stop`][gitlab-ci-yml] in the `test` stage can be used to
  stop a Review App manually, and is also started by GitLab once a branch is
  deleted.
- Review Apps are cleaned up regularly using a pipeline schedule that runs
  the [`schedule:review-cleanup`][gitlab-ci-yml] job.

## QA runs

On every [pipeline][gitlab-pipeline] during the `test` stage, the
`review-qa-smoke` job is automatically started: it runs the QA smoke suite.
You can also manually start the `review-qa-all`: it runs the QA full suite.

Note that both jobs first wait for the `review-deploy` job to be finished.

## Performance Metrics

On every [pipeline][gitlab-pipeline] during the `test` stage, the
`review-performance` job is automatically started: this job does basic
browser performance testing using [Sitespeed.io Container](https://docs.gitlab.com/ee/user/project/merge_requests/browser_performance_testing.html) .

This job waits for the `review-deploy` job to be finished.

## How to?

### Log into my Review App?

The default username is `root` and its password can be found in the 1Password
secure note named **gitlab-{ce,ee} Review App's root password**.

### Enable a feature flag for my Review App?

1. Open your Review App and log in as documented above.
1. Create a personal access token.
1. Enable the feature flag using the [Feature flag API](../../api/features.md).

### Find my Review App slug?

1. Open the `review-deploy` job.
1. Look for `Checking for previous deployment of review-*`.
1. For instance for `Checking for previous deployment of review-qa-raise-e-12chm0`,
  your Review App slug would be `review-qa-raise-e-12chm0` in this case.

### Run a Rails console?

1. [Filter Workloads by your Review App slug](https://console.cloud.google.com/kubernetes/workload?project=gitlab-review-apps)
  , e.g. `review-29951-issu-id2qax`.
1. Find and open the `task-runner` Deployment, e.g. `review-29951-issu-id2qax-task-runner`.
1. Click on the Pod in the "Managed pods" section, e.g. `review-29951-issu-id2qax-task-runner-d5455cc8-2lsvz`.
1. Click on the `KUBECTL` dropdown, then `Exec` -> `task-runner`.
1. Replace `-c task-runner -- ls` with `-it -- gitlab-rails console` from the
  default command or
  - Run `kubectl exec --namespace review-apps-ce review-29951-issu-id2qax-task-runner-d5455cc8-2lsvz -it -- gitlab-rails console`
    and
  - Replace `review-apps-ce` with `review-apps-ee` if the Review App
    is running EE, and
  - Replace `review-29951-issu-id2qax-task-runner-d5455cc8-2lsvz`
    with your Pod's name.

### Dig into a Pod's logs?

1. [Filter Workloads by your Review App slug](https://console.cloud.google.com/kubernetes/workload?project=gitlab-review-apps)
  , e.g. `review-1979-1-mul-dnvlhv`.
1. Find and open the `migrations` Deployment, e.g.
  `review-1979-1-mul-dnvlhv-migrations.1`.
1. Click on the Pod in the "Managed pods" section, e.g.
  `review-1979-1-mul-dnvlhv-migrations.1-nqwtx`.
1. Click on the `Container logs` link.

## Frequently Asked Questions

**Isn't it too much to trigger CNG image builds on every test run? This creates
thousands of unused Docker images.**

  > We have to start somewhere and improve later. Also, we're using the
  CNG-mirror project to store these Docker images so that we can just wipe out
  the registry at some point, and use a new fresh, empty one.

**How big are the Kubernetes clusters (`review-apps-ce` and `review-apps-ee`)?**

  > The clusters are currently set up with a single pool of preemptible nodes,
  with a minimum of 1 node and a maximum of 50 nodes.

**What are the machine running on the cluster?**

  > We're currently using `n1-standard-16` (16 vCPUs, 60 GB memory) machines.

**How do we secure this from abuse? Apps are open to the world so we need to
find a way to limit it to only us.**

  > This isn't enabled for forks.

## Other resources

* [Review Apps integration for CE/EE (presentation)](https://docs.google.com/presentation/d/1QPLr6FO4LduROU8pQIPkX1yfGvD13GEJIBOenqoKxR8/edit?usp=sharing)

[charts-1068]: https://gitlab.com/charts/gitlab/issues/1068
[gitlab-pipeline]: https://gitlab.com/gitlab-org/gitlab-ce/pipelines/44362587
[gitlab:assets:compile]: https://gitlab.com/gitlab-org/gitlab-ce/-/jobs/149511610
[review-build-cng]: https://gitlab.com/gitlab-org/gitlab-ce/-/jobs/149511623
[review-deploy]: https://gitlab.com/gitlab-org/gitlab-ce/-/jobs/149511624
[cng-mirror]: https://gitlab.com/gitlab-org/build/CNG-mirror
[cng-pipeline]: https://gitlab.com/gitlab-org/build/CNG-mirror/pipelines/44364657
[cng-mirror-registry]: https://gitlab.com/gitlab-org/build/CNG-mirror/container_registry
[helm-chart]: https://gitlab.com/charts/gitlab/
[review-apps-ce]: https://console.cloud.google.com/kubernetes/clusters/details/us-central1-a/review-apps-ce?project=gitlab-review-apps
[review-apps-ee]: https://console.cloud.google.com/kubernetes/clusters/details/us-central1-b/review-apps-ee?project=gitlab-review-apps
[review-apps.sh]: https://gitlab.com/gitlab-org/gitlab-ee/blob/master/scripts/review_apps/review-apps.sh
[automated_cleanup.rb]: https://gitlab.com/gitlab-org/gitlab-ee/blob/master/scripts/review_apps/automated_cleanup.rb
[Auto-DevOps.gitlab-ci.yml]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml
[gitlab-ci-yml]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/.gitlab-ci.yml
[gitlab-k8s-integration]: https://docs.gitlab.com/ee/user/project/clusters/index.html
[password-bug]: https://gitlab.com/gitlab-org/gitlab-ce/issues/53621

---

[Return to Testing documentation](index.md)
