---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Tutorial: Use Auto DevOps to deploy an application to Google Kubernetes Engine **(FREE)**

This step-by-step guide helps you use [Auto DevOps](index.md) to
In this tutorial, we'll help you to get started with [Auto DevOps](index.md)
through an example of how to deploy an application to Google Kubernetes Engine (GKE).

You are using the GitLab native Kubernetes integration, so you don't need
to create a Kubernetes cluster manually using the Google Cloud Platform console.
You are creating and deploying an application that you create from a GitLab template.

These instructions also work for self-managed GitLab instances.
Ensure your own [runners are configured](../../ci/runners/index.md) and
[Google OAuth is enabled](../../integration/google.md).

To deploy a project to Google Kubernetes Engine, follow the steps below:

1. [Configure your Google account](#configure-your-google-account)
1. [Create a new project from a template](#create-a-new-project-from-a-template)
1. [Create a Kubernetes cluster from GitLab](#create-a-kubernetes-cluster-from-gitlab)
1. [Install Ingress](#install-ingress)
1. [Configure your base domain](#configure-your-base-domain)
1. [Enable Auto DevOps](#enable-auto-devops-optional)
1. [Deploy the application](#deploy-the-application)

## Configure your Google account

Before creating and connecting your Kubernetes cluster to your GitLab project,
you need a [Google Cloud Platform account](https://console.cloud.google.com).
Sign in with an existing Google account, such as the one you use to access Gmail
or Google Drive, or create a new one.

1. Follow the steps described in the ["Before you begin" section](https://cloud.google.com/kubernetes-engine/docs/quickstart#before-you-begin)
   of the Kubernetes Engine documentation to enable the required APIs and related services.
1. Ensure you've created a [billing account](https://cloud.google.com/billing/docs/how-to/manage-billing-account)
   with Google Cloud Platform.

NOTE:
Every new Google Cloud Platform (GCP) account receives [$300 in credit](https://console.cloud.google.com/freetrial),
and in partnership with Google, GitLab is able to offer an additional $200 for new
GCP accounts to get started with the GitLab integration with Google Kubernetes Engine.
[Follow this link](https://cloud.google.com/partners/partnercredit/?pcn_code=0014M00001h35gDQAQ#contact-form)
and apply for credit.

## Create a new project from a template

Use a GitLab project template to get started. As the name suggests,
those projects provide a bare-bones application built on some well-known frameworks.

1. On the top bar in GitLab, select the plus icon (**{plus-square}**), and select
   **New project/repository**.
1. Go to the **Create from template** tab, where you can choose a Ruby on
   Rails, Spring, or NodeJS Express project.
   For this tutorial, use the Ruby on Rails template.

   ![Select project template](img/guide_project_template_v12_3.png)

1. Give your project a name, optionally a description, and make it public so that
   you can take advantage of the features available in the
   [GitLab Ultimate plan](https://about.gitlab.com/pricing/).

   ![Create project](img/guide_create_project_v12_3.png)

1. Select **Create project**.

Now that you've created a project, create the Kubernetes cluster
to deploy this project to.

## Create a Kubernetes cluster from GitLab

1. On your project's landing page, select the button **Add Kubernetes cluster**.

   ![Project landing page](img/guide_project_landing_page_v12_10.png)

1. On the **Add a Kubernetes cluster integration** page, select the **Create new cluster** tab,
   then select **Google GKE**.

1. Connect with your Google account, and select **Allow** to allow access to your
   Google account. (This authorization request is only displayed the first time
   you connect GitLab with your Google account.)

   After authorizing access, the **Add a Kubernetes cluster integration** page
   is displayed.

1. In the **Enter the details for your Kubernetes cluster** section, provide
   details about your cluster:

   - **Kubernetes cluster name**
   - **Environment scope** - Leave this field unchanged.
   - **Google Cloud Platform project** - Select a project. When you
     [configured your Google account](#configure-your-google-account), a project
     should have already been created for you.
   - **Zone** - The [region/zone](https://cloud.google.com/compute/docs/regions-zones/) to
     create the cluster in.
   - **Number of nodes**
   - **Machine type** - For more information about
     [machine types](https://cloud.google.com/compute/docs/machine-types), see Google's documentation.
   - **Enable Cloud Run for Anthos** - Select this checkbox to use the
     [Cloud Run](../../user/project/clusters/add_gke_clusters.md#cloud-run-for-anthos),
     Istio, and HTTP Load Balancing add-ons for this cluster.
   - **GitLab-managed cluster** - Select this checkbox to
     [allow GitLab to manage namespace and service accounts](../../user/project/clusters/index.md#gitlab-managed-clusters) for this cluster.

1. Select **Create Kubernetes cluster**.

After a couple of minutes, the cluster is created. You can also see its
status on your [GCP dashboard](https://console.cloud.google.com/kubernetes).

## Install Ingress

After your cluster is running, you must install NGINX Ingress Controller as a
load balancer, to route traffic from the internet to your application.
Install the NGINX Ingress Controller
through the GitLab [Cluster management project template](../../user/clusters/management_project_template.md),
or manually with Google Cloud Shell:

1. Go to your cluster's details page, and select the **Advanced Settings** tab.
1. Select the link to Google Kubernetes Engine to visit the cluster on Google Cloud Console.
1. On the GKE cluster page, select **Connect**, then select **Run in Cloud Shell**.
1. After the Cloud Shell starts, run these commands to install NGINX Ingress Controller:

   ```shell
   kubectl create ns gitlab-managed-apps
   helm repo add stable https://charts.helm.sh/stable
   helm repo update
   helm install ingress stable/nginx-ingress -n gitlab-managed-apps

   # Check that the ingress controller is installed successfully
   kubectl get service ingress-nginx-ingress-controller -n gitlab-managed-apps
   ```

## Configure your base domain

Follow these steps to configure the base domain where you access your apps.

1. A few minutes after you install NGINX, the load balancer obtains an IP address, and you can
   get the external IP address with the following command:

   ```shell
   kubectl get service ingress-nginx-ingress-controller -n gitlab-managed-apps -ojson | jq -r '.status.loadBalancer.ingress[].ip'
   ```

   Replace `gitlab-managed-apps` if you have overwritten your namespace.

   Copy this IP address, as you need it in the next step.

1. Go back to the cluster page on GitLab, and go to the **Details** tab.
   - Add your **Base domain**. For this example, use the domain `<IP address>.nip.io`.
   - Select **Save changes**.

   ![Cluster Base Domain](img/guide_base_domain_v12_3.png)

## Enable Auto DevOps (optional)

While Auto DevOps is enabled by default, Auto DevOps can be disabled at both
the instance level (for self-managed instances) and the group level. Complete
these steps to enable Auto DevOps if it's disabled:

1. Go to **Settings > CI/CD > Auto DevOps**, and select **Expand**.
1. Select **Default to Auto DevOps pipeline** to display more options.
1. In **Deployment strategy**, select your desired [continuous deployment strategy](requirements.md#auto-devops-deployment-strategy)
   to deploy the application to production after the pipeline successfully runs on the default branch.
1. Select **Save changes**.

   ![Auto DevOps settings](img/guide_enable_autodevops_v12_3.png)

After you save your changes, GitLab creates a new pipeline. To view it, go to
**{rocket}** **CI/CD > Pipelines**.

In the next section, we explain what each job does in the pipeline.

## Deploy the application

When your pipeline runs, what is it doing?

To view the jobs in the pipeline, select the pipeline's status badge. The
**{status_running}** icon displays when pipeline jobs are running, and updates
without refreshing the page to **{status_success}** (for success) or
**{status_failed}** (for failure) when the jobs complete.

The jobs are separated into stages:

![Pipeline stages](img/guide_pipeline_stages_v13_0.png)

- **Build** - The application builds a Docker image and uploads it to your project's
  [Container Registry](../../user/packages/container_registry/index.md) ([Auto Build](stages.md#auto-build)).
- **Test** - GitLab runs various checks on the application, but all jobs except `test`
  are allowed to fail in the test stage:

  - The `test` job runs unit and integration tests by detecting the language and
    framework ([Auto Test](stages.md#auto-test))
  - The `code_quality` job checks the code quality and is allowed to fail
    ([Auto Code Quality](stages.md#auto-code-quality))
  - The `container_scanning` job checks the Docker container if it has any
    vulnerabilities and is allowed to fail ([Auto Container Scanning](stages.md#auto-container-scanning))
  - The `dependency_scanning` job checks if the application has any dependencies
    susceptible to vulnerabilities and is allowed to fail
    ([Auto Dependency Scanning](stages.md#auto-dependency-scanning)) **(ULTIMATE)**
  - Jobs suffixed with `-sast` run static analysis on the current code to check for potential
    security issues, and are allowed to fail ([Auto SAST](stages.md#auto-sast)) **(ULTIMATE)**
  - The `secret-detection` job checks for leaked secrets and is allowed to fail ([Auto Secret Detection](stages.md#auto-secret-detection)) **(ULTIMATE)**
  - The `license_scanning` job searches the application's dependencies to determine each of their
    licenses and is allowed to fail
    ([Auto License Compliance](stages.md#auto-license-compliance)) **(ULTIMATE)**

- **Review** - Pipelines on the default branch include this stage with a `dast_environment_deploy` job.
  To learn more, see [Dynamic Application Security Testing (DAST)](../../user/application_security/dast/index.md).

- **Production** - After the tests and checks finish, the application deploys in
  Kubernetes ([Auto Deploy](stages.md#auto-deploy)).

- **Performance** - Performance tests are run on the deployed application
  ([Auto Browser Performance Testing](stages.md#auto-browser-performance-testing)). **(PREMIUM)**

- **Cleanup** - Pipelines on the default branch include this stage with a `stop_dast_environment` job.

After running a pipeline, you should view your deployed website and learn how
to monitor it.

### Monitor your project

After successfully deploying your application, you can view its website and check
on its health on the **Environments** page by navigating to
**Deployments > Environments**. This page displays details about
the deployed applications, and the right-hand column displays icons that link
you to common environment tasks:

![Environments](img/guide_environments_v12_3.png)

- **Open live environment** (**{external-link}**) - Opens the URL of the application deployed in production
- **Monitoring** (**{chart}**) - Opens the metrics page where Prometheus collects data
  about the Kubernetes cluster and how the application
  affects it in terms of memory usage, CPU usage, and latency
- **Deploy to** (**{play}** **{angle-down}**) - Displays a list of environments you can deploy to
- **Terminal** (**{terminal}**) - Opens a [web terminal](../../ci/environments/index.md#web-terminals)
  session inside the container where the application is running
- **Re-deploy to environment** (**{repeat}**) - For more information, see
  [Retrying and rolling back](../../ci/environments/index.md#retry-or-roll-back-a-deployment)
- **Stop environment** (**{stop}**) - For more information, see
  [Stopping an environment](../../ci/environments/index.md#stop-an-environment)

GitLab displays the [Deploy Board](../../user/project/deploy_boards.md) below the
environment's information, with squares representing pods in your
Kubernetes cluster, color-coded to show their status. Hovering over a square on
the deploy board displays the state of the deployment, and selecting the square
takes you to the pod's logs page.

NOTE:
The example shows only one pod hosting the application at the moment, but you can add
more pods by defining the [`REPLICAS` CI/CD variable](customize.md#cicd-variables)
in **Settings > CI/CD > Variables**.

### Work with branches

Following the [GitLab flow](../gitlab_flow.md#working-with-feature-branches),
you should next create a feature branch to add content to your application:

1. In your project's repository, go to the following file: `app/views/welcome/index.html.erb`.
   This file should only contain a paragraph: `<p>You're on Rails!</p>`.
1. Open the GitLab [Web IDE](../../user/project/web_ide/index.md) to make the change.
1. Edit the file so it contains:

   ```html
   <p>You're on Rails! Powered by GitLab Auto DevOps.</p>
   ```

1. Stage the file. Add a commit message, then create a new branch and a merge request
   by selecting **Commit**.

   ![Web IDE commit](img/guide_ide_commit_v12_3.png)

After submitting the merge request, GitLab runs your pipeline, and all the jobs
in it, as [described previously](#deploy-the-application), in addition to
a few more that run only on branches other than the default branch.

![Merge request](img/guide_merge_request_v12_3.png)

After a few minutes a test fails, which means a test was
'broken' by your change. Select the failed `test` job to see more information
about it:

```plaintext
Failure:
WelcomeControllerTest#test_should_get_index [/app/test/controllers/welcome_controller_test.rb:7]:
<You're on Rails!> expected but was
<You're on Rails! Powered by GitLab Auto DevOps.>..
Expected 0 to be >= 1.

bin/rails test test/controllers/welcome_controller_test.rb:4
```

To fix the broken test:

1. Return to the **Overview** page for your merge request, and select **Open in Web IDE**.
1. In the left-hand directory of files, find the `test/controllers/welcome_controller_test.rb`
   file, and select it to open it.
1. Change line 7 to say `You're on Rails! Powered by GitLab Auto DevOps.`
1. Select **Commit**.
1. In the left-hand column, under **Unstaged changes**, select the checkmark icon
   (**{stage-all}**) to stage the changes.
1. Write a commit message, and select **Commit**.

Return to the **Overview** page of your merge request, and you should not only
see the test passing, but also the application deployed as a
[review application](stages.md#auto-review-apps). You can visit it by selecting
the **View app** **{external-link}** button to see your changes deployed.

![Review app](img/guide_merge_request_review_app_v12_3.png)

After merging the merge request, GitLab runs the pipeline on the default branch,
and then deploys the application to production.

## Conclusion

After implementing this project, you should have a solid understanding of the basics of Auto DevOps.
You started from building and testing, to deploying and monitoring an application
all in GitLab. Despite its automatic nature, Auto DevOps can also be configured
and customized to fit your workflow. Here are some helpful resources for further reading:

1. [Auto DevOps](index.md)
1. [Multiple Kubernetes clusters](multiple_clusters_auto_devops.md)
1. [Incremental rollout to production](customize.md#incremental-rollout-to-production) **(PREMIUM)**
1. [Disable jobs you don't need with CI/CD variables](customize.md#cicd-variables)
1. [Use your own buildpacks to build your application](customize.md#custom-buildpacks)
1. [Prometheus monitoring](../../user/project/integrations/prometheus.md)
