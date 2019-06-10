# Review Apps

Review Apps are automatically deployed by each pipeline, both in
[CE](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/22010) and
[EE](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/6665).

## How does it work?

### CI/CD architecture diagram

![Review Apps CI/CD architecture](img/review_apps_cicd_architecture.png)

<details>
<summary>Show mermaid source</summary>
<pre>
graph TD
    build-qa-image -.->|once the `prepare` stage is done| gitlab:assets:compile
    review-build-cng -->|triggers a CNG-mirror pipeline and wait for it to be done| CNG-mirror
    review-build-cng -.->|once the `test` stage is done| review-deploy
    review-deploy -.->|once the `review` stage is done| review-qa-smoke

subgraph 1. gitlab-ce/ee `prepare` stage
    build-qa-image
    end

subgraph 2. gitlab-ce/ee `test` stage
    gitlab:assets:compile -->|plays dependent job once done| review-build-cng
    end

subgraph 3. gitlab-ce/ee `review` stage
    review-deploy["review-deploy<br /><br />Helm deploys the Review App using the Cloud<br/>Native images built by the CNG-mirror pipeline.<br /><br />Cloud Native images are deployed to the `review-apps-ce` or `review-apps-ee`<br />Kubernetes (GKE) cluster, in the GCP `gitlab-review-apps` project."]
    end

subgraph 4. gitlab-ce/ee `qa` stage
    review-qa-smoke[review-qa-smoke<br /><br />gitlab-qa runs the smoke suite against the Review App.]
    end

subgraph CNG-mirror pipeline
    CNG-mirror>Cloud Native images are built];
    end
</pre>
</details>

### Detailed explanation

1. On every [pipeline][gitlab-pipeline] during the `test` stage, the
   [`gitlab:assets:compile`][gitlab:assets:compile] job is automatically started.
   - Once it's done, it starts the [`review-build-cng`][review-build-cng]
     manual job since the [`CNG-mirror`][cng-mirror] pipeline triggered in the
     following step depends on it.
1. The [`review-build-cng`][review-build-cng] job [triggers a pipeline][cng-mirror-pipeline]
   in the [`CNG-mirror`][cng-mirror] project.
   - The [`CNG-mirror`][cng-mirror-pipeline] pipeline creates the Docker images of
     each component (e.g. `gitlab-rails-ee`, `gitlab-shell`, `gitaly` etc.)
     based on the commit from the [GitLab pipeline][gitlab-pipeline] and stores
     them in its [registry][cng-mirror-registry].
   - We use the [`CNG-mirror`][cng-mirror] project so that the `CNG`, (**C**loud
     **N**ative **G**itLab), project's registry is not overloaded with a
     lot of transient Docker images.
   - Note that the official CNG images are built by the `cloud-native-image`
     job, which runs only for tags, and triggers itself a [`CNG`][cng] pipeline.
1. Once the `test` stage is done, the [`review-deploy`][review-deploy] job
   deploys the Review App using [the official GitLab Helm chart][helm-chart] to
   the [`review-apps-ce`][review-apps-ce] / [`review-apps-ee`][review-apps-ee]
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

- If the `review-deploy` job keep failing (note that we already retry it twice),
  please post a message in the `#quality` channel and/or create a ~Quality ~bug
  issue with a link to your merge request. Note that the deployment failure can
  reveal an actual problem introduced in your merge request (i.e. this isn't
  necessarily a transient failure)!
- If the `review-qa-smoke` job keep failing (note that we already retry it twice),
  please check the job's logs: you could discover an actual problem introduced in
  your merge request. You can also download the artifacts to see screenshots of
  the page at the time the failures occurred. If you don't find the cause of the
  failure or if it seems unrelated to your change, please post a message in the
  `#quality` channel and/or create a ~Quality ~bug issue with a link to your
  merge request.
- The manual [`review-stop`][gitlab-ci-yml] in the `test` stage can be used to
  stop a Review App manually, and is also started by GitLab once a merge
  request's branch is deleted after being merged.
- Review Apps are cleaned up regularly via a pipeline schedule that runs
  the [`schedule:review-cleanup`][gitlab-ci-yml] job.
- The Kubernetes cluster is connected to the `gitlab-{ce,ee}` projects using
  [GitLab's Kubernetes integration][gitlab-k8s-integration]. This basically
  allows to have a link to the Review App directly from the merge request
  widget.

## QA runs

On every [pipeline][gitlab-pipeline] in the `qa` stage (which comes after the
`review` stage), the `review-qa-smoke` job is automatically started and it runs
the QA smoke suite.

You can also manually start the `review-qa-all`: it runs the full QA suite.

## Performance Metrics

On every [pipeline][gitlab-pipeline] in the `qa` stage, the
`review-performance` job is automatically started: this job does basic
browser performance testing using a
[Sitespeed.io Container](../../user/project/merge_requests/browser_performance_testing.md).

## How to:

### Log into my Review App

The default username is `root` and its password can be found in the 1Password
secure note named **gitlab-{ce,ee} Review App's root password**.

### Enable a feature flag for my Review App

1. Open your Review App and log in as documented above.
1. Create a personal access token.
1. Enable the feature flag using the [Feature flag API](../../api/features.md).

### Find my Review App slug

1. Open the `review-deploy` job.
1. Look for `Checking for previous deployment of review-*`.
1. For instance for `Checking for previous deployment of review-qa-raise-e-12chm0`,
   your Review App slug would be `review-qa-raise-e-12chm0` in this case.

### Run a Rails console

1. [Filter Workloads by your Review App slug](https://console.cloud.google.com/kubernetes/workload?project=gitlab-review-apps)
  , e.g. `review-qa-raise-e-12chm0`.
1. Find and open the `task-runner` Deployment, e.g. `review-qa-raise-e-12chm0-task-runner`.
1. Click on the Pod in the "Managed pods" section, e.g. `review-qa-raise-e-12chm0-task-runner-d5455cc8-2lsvz`.
1. Click on the `KUBECTL` dropdown, then `Exec` -> `task-runner`.
1. Replace `-c task-runner -- ls` with `-it -- gitlab-rails console` from the
   default command or
   - Run `kubectl exec --namespace review-apps-ce review-qa-raise-e-12chm0-task-runner-d5455cc8-2lsvz -it -- gitlab-rails console` and
     - Replace `review-apps-ce` with `review-apps-ee` if the Review App
       is running EE, and
     - Replace `review-qa-raise-e-12chm0-task-runner-d5455cc8-2lsvz`
       with your Pod's name.

### Dig into a Pod's logs

1. [Filter Workloads by your Review App slug](https://console.cloud.google.com/kubernetes/workload?project=gitlab-review-apps),
   e.g. `review-qa-raise-e-12chm0`.
1. Find and open the `migrations` Deployment, e.g.
   `review-qa-raise-e-12chm0-migrations.1`.
1. Click on the Pod in the "Managed pods" section, e.g.
   `review-qa-raise-e-12chm0-migrations.1-nqwtx`.
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
[cng]: https://gitlab.com/gitlab-org/build/CNG
[cng-mirror-pipeline]: https://gitlab.com/gitlab-org/build/CNG-mirror/pipelines/44364657
[cng-mirror-registry]: https://gitlab.com/gitlab-org/build/CNG-mirror/container_registry
[helm-chart]: https://gitlab.com/charts/gitlab/
[review-apps-ce]: https://console.cloud.google.com/kubernetes/clusters/details/us-central1-a/review-apps-ce?project=gitlab-review-apps
[review-apps-ee]: https://console.cloud.google.com/kubernetes/clusters/details/us-central1-b/review-apps-ee?project=gitlab-review-apps
[review-apps.sh]: https://gitlab.com/gitlab-org/gitlab-ee/blob/master/scripts/review_apps/review-apps.sh
[automated_cleanup.rb]: https://gitlab.com/gitlab-org/gitlab-ee/blob/master/scripts/review_apps/automated_cleanup.rb
[Auto-DevOps.gitlab-ci.yml]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml
[gitlab-ci-yml]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/.gitlab-ci.yml
[gitlab-k8s-integration]: ../../user/project/clusters/index.md
[password-bug]: https://gitlab.com/gitlab-org/gitlab-ce/issues/53621

---

[Return to Testing documentation](index.md)
