# Getting started with Auto DevOps

This is a step-by-step guide that will help you deploy a project hosted on
GitLab.com to Google Kubernetes Engine, using [Auto DevOps](index.md).

We will use the Kubernetes integration that GitLab provides, so you won't have
to create a Kubernetes cluster manually using the GCP console.

## Configuring your Google account

Before creating and connecting your Kubernetes cluster to your GitLab project,
you have to set up your Google Cloud account. If you don't already have one, go
and create it at https://console.cloud.google.com. If you already have a
Google account that you use to access Gmail, etc., you can use it to sign in
the Google Cloud.

1. Follow the steps as outlined in the ["Before you begin" section of the Kubernetes Engine docs](https://cloud.google.com/kubernetes-engine/docs/quickstart#before-you-begin)
   in order for the required APIs and related services to be enabled.
1. Make sure you have created a [billing account](https://cloud.google.com/billing/docs/how-to/manage-billing-account).

TIP: **Tip:**
Every new Google Cloud Platform (GCP) account receives [$300 in credit](https://console.cloud.google.com/freetrial),
and in partnership with Google, GitLab is able to offer an additional $200 for new GCP accounts to get started with GitLab's
Google Kubernetes Engine Integration. All you have to do is [follow this link](https://goo.gl/AaJzRW) and apply for credit.

## Creating a new project from a template

We will use one of GitLab's project templates to get started. AS the name suggests,
those projects provide a barebone of an application built on some well known frameworks.

1. Find the plus icon (**+**) at the top of the navigation bar, click it and select
   **New project**.
1. Go to the **Create from template** tab where you can choose among a Ruby on
   Rails, a Spring, or a NodeJS Express project. For the sake of the example
   let's use the Ruby on Rails template.

    ![Select project template](img/guide_project_template.png)

1. Give your project a name, optionally a description, and make it public so that
   you can take advantage of the features available in the
   [GitLab Gold plan](https://about.gitlab.com/pricing/#gitlab-com).

    ![Create project](img/guide_create_project.png)

1. Finally, click on the **Create project** button.

Now that the project is created, the next step is to create the Kubernetes cluster
under which this application will be deployed.

## Creating a Kubernetes cluster

One thing you should notice after you created the project is the **Add Kubernetes cluster**
button on the project's landing page. Go ahead and click it.

![Project landing page](img/guide_project_landing_page.png)

TIP: **Tip:**
Another way is to navigate to **Operations > Kubernetes** and click on
**Add Kubernetes cluster**.

From there on, let's see how to create a new Kubernetes cluster on GKE:

1. Choose **Create on Google Kubernetes Engine**.

    ![Choose GKE](img/guide_choose_gke.png)

1. Sign in with Google.

    ![Google sign in](img/guide_google_signin.png)

1. Connect with your Google account and press **Allow** when asked (this will
   be shown only the first time you connect GitLab with your Google account).

    ![Google auth](img/guide_google_auth.png)

1. The last step is to fill in the cluster details. Give it a name, leave the
   environment scope as is, and choose the GCP project under which the cluster
   will be created (if you followed the instructions when you
   [configured your Google account](#configuring-your-google-account), a project
   should have been created for you). Next, choose the
   [region/zone](https://cloud.google.com/compute/docs/regions-zones/) under which the
   cluster will be created, enter the number of nodes you want it to have, and
   finally choose their [machine type](https://cloud.google.com/compute/docs/machine-types).

    ![GitLab GKE cluster details](img/guide_gitlab_gke_details.png)

1. Once ready, hit the **Create Kubernetes cluster** button.

After a couple of minutes, the cluster will be created. You can also see its
status on your [GCP dashboard](https://console.cloud.google.com/kubernetes).

The next step is to install some applications on your cluster that are needed
to take full advantage of Auto DevOps.

## Installing Helm, Ingress and Prometheus

GitLab's Kubernetes integration comes with some
[pre-defined applications](../../user/project/clusters/index.md#installing-applications)
for you to install.

![Cluster applications](img/guide_cluster_apps.png)

The first one to install is Helm Tiller, a package manager for Kubernetes, which
is needed in order to install the rest of the applications. Go ahead and click
its **Install** button.

Once it's installed, the other applications that rely on it will have their **Install**
button enabled. For this guide, we need Ingress and Prometheus. Ingress provides
load balancing, SSL termination, and name-based virtual hosting, using NGINX behind
the scenes. Prometheus is an open-source monitoring and alerting system that we'll
use to supervise the deployed application. We will not install GitLab Runner as
we'll use the shared Runners that GitLab.com provides.

After the Ingress is installed, wait a few seconds and copy the IP address that
will show up, we'll use in the next step when enabling Auto DevOps.

## Enabling Auto DevOps

Now that the Kubernetes cluster is set up and ready, let's enable Auto DevOps.

1. First, navigate to **Settings > CI/CD > Auto DevOps**.

1. Select **Enable Auto DevOps**.
1. Add in your base **Domain** by using the one GitLab suggests. Note that
   generally, you would associate the IP address with a domain name on your
   registrar's settings. In this case, for the sake of the guide, we will use
   an alternative DNS that will map any domain name of the scheme
   `anything.ip_address.nip.io` to the corresponding `ip_address`. For example,
   if the IP address of the Ingress is `1.2.3.4`, the domain name to fill in
   would be `1.2.3.4.nip.io`.
1. Lastly, let's select the [continuous deployment strategy](index.md#deployment-strategy)
   which will automatically deploy the application to production once the pipeline
   successfully runs on `master` branch.
1. Hit **Save changes** for the changes to take effect.

    ![Auto DevOps settings](img/guide_enable_autodevops.png)

Once you complete all the above and save your changes, a new pipeline will be
automatically created. Go to **CI/CD > Pipelines** to check it out.

![First pipeline](img/guide_first_pipeline.png)

In the next section we'll break down the pipeline and explain what each job does.

## Deploying the application

So, by now you should see the pipeline running, but what is it running exactly?

To navigate inside the pipeline, click on its status badge (it should say running)
The pipeline is split into 4 stages, each running a couple of jobs.

![Pipeline stages](img/guide_pipeline_stages.png)

In the **build** stage, the application is built into a Docker image and then
uploaded to your project's [Container Registry](../../user/project/container_registry.md) ([Auto Build](index.md#auto-build)).

In the **test** stage, GitLab runs various checks on the application:

- The `test` job runs unit and integration tests by detecting the language and
  framework ([Auto Test](index.md#auto-test))
- The `code_quality` job checks the code quality and is allowed to fail
  ([Auto Code Quality](index.md#auto-code-quality)) **[STARTER]**
- The `container_scanning` job checks the Docker container if it has any
  vulnerabilities and is allowed to fail ([Auto Container Scanning](index.md#auto-container-scanning))
- The `dependency_scanning` job checks if the application has any dependencies
  susceptible to vulnerabilities and is allowed to fail ([Auto Dependency Scanning](index.md#auto-dependency-scanning)) **[ULTIMATE]**
- The `sast` job runs static analysis on the current code and checks for potential
  security issues and is allowed to fail([Auto SAST](index.md#auto-sast)) **[ULTIMATE]**
- The `license_management` job searches the application's dependencies for their
  license and is allowed to fail ([Auto License Management](index.md#auto-license-management)) **[ULTIMATE]**

NOTE: **Note:**
As you might have noticed, all jobs except `test` are allowed to fail in the
test stage.

The **production** stage is run after the tests and checks finish, and it automatically
deploys the application in Kubernetes ([Auto Deploy](index.md#auto-deploy)).

Lastly, in the **performance** stage, some performance tests will run
on the deployed application
([Auto Browser Performance Testing](index.md#auto-browser-performance-testing)). **[PREMIUM]**

---

The URL for the deployed application can be found under the **Environments**
page where you can also monitor your application. Let's explore that.

### Monitoring

Now that the application is successfully deployed, let's navigate to its
website, by first going to **Operations > Environments**.

![Environments](img/guide_environments.png)

This is the **Environments** where you can see some details about the deployed
applications. At the upper right or the production environment, you should see
some icons:

- The first one will take you to the URL of the application that is deployed in
  production. It's a very simple page, but the purpose is that it works!
- The next icon with the little graph will take you to the metrics page where
  prometheus collects data about the Kubernetes cluster and how the application
  affects it (in terms of memory/CPU usage, latency etc.).

    ![Environments metrics](img/guide_environments_metrics.png)

- The third icon is the [web terminal](../../ci/environments.md#web-terminals)
  and it will open a terminal session right inside the container where the
  application is running.

Right below, there is the
[Deploy Board](https://docs.gitlab.com/ee/user/project/deploy_boards.md).
The squares represent pods in your Kubernetes cluster that are associated with
the given environment. Hovering above each square you can see the state of a
deployment and clicking on the square will take you to the pod's logs page.

TIP: **Tip:**
There is only one pod hosting the application at the moment, but you can add
more pods by defining the [`REPLICAS` variable](index.md#environment-variables)
under **Settings > CI/CD > Variables**.

### Working with branches

Following the [GitLab flow](../../workflow/gitlab_flow.md#working-with-feature-branches)
let's create a feature branch that will add some content to the application.

Under your repository, navigate to the following file: `app/views/welcome/index.html.erb`.
By now, it should only contain a paragraph: `<p>You're on Rails!</p>`, so let's
start adding content. Let's use GitLab's [Web IDE]() to make the change. Once
you're on the Web IDE, make the following change:

```html
<p>You're on Rails! Powered by GitLab Auto DevOps.</p>
```

Stage the file, add a commit message, and create a new branch and a merge request
by clicking **Commit**.

![Web IDE commit](img/guide_ide_commit.png)

Once you submit the merge request, you'll see the pipeline running. This will
run all the jobs as [described previously](#deploying-the-application), as well
a few more that run only on branches other than `master`.

![Merge request](img/guide_merge_request.png)

After a few minutes you'll realize that there was a failure in a test.
That means that there's a test that was broken when we made the change.
Navigating in the `test` job that failed, you can see what the broken test is:

```
Failure:
WelcomeControllerTest#test_should_get_index [/app/test/controllers/welcome_controller_test.rb:7]:
<You're on Rails!> expected but was
<You're on Rails! Powered by GitLab Auto DevOps.>..
Expected 0 to be >= 1.

bin/rails test test/controllers/welcome_controller_test.rb:4
```

Let's fix that:

1. Back to the merge request, click the **Web IDE** button.
1. Find the `test/controllers/welcome_controller_test.rb` file and open it.
1. Change line 7 to say `You're on Rails! Powered by GitLab Auto DevOps.`
1. Click **Commit**.
1. On your left, under "Unstaged changes", click the little checkmark icon
   to stage the changes.
1. Write a commit message and hit **Commit**

Now, if you go back to the merge request you should see not only the test passing,
but the application deployed as a [review app](index.md#auto-review-apps). You
can visit it by following the URL in the merge request. The changes that we
previously made should be there.

![Review app](img/guide_merge_request_review_app.png)

Once you merge the merge request, the pipeline will run on the `master` branch,
and the application will be eventually deployed straight to production.

## Conclusion

By now, you should have gained a solid understanding of how Auto DevOps works.
We started from building and testing to deploying and monitoring an application
all within GitLab. In spite of its auto nature, this doesn't mean that you can't
configure and customize Auto DevOps to fit your workflow. Here are a few
interesting links:

1. [Auto DevOps](index.md)
1. [Multiple Kubernetes clusters](index.md#using-multiple-kubernetes-clusters) **[PREMIUM]**
1. [Incremental rollout to production](index.md#incremental-rollout-to-production) **[PREMIUM]**
1. [Disable jobs you don't need with environment variables](index.md#environment-variables)
1. [Use a static IP for your cluster](../../user/project/clusters/index.md#using-a-static-ip)
1. [Use your own buildpacks to build your application](index.md#custom-buildpacks)
1. [Prometheus monitoring](../../user/project/integrations/prometheus.md)
